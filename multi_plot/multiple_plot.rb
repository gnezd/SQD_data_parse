# prototype multiple plot
require '../lib.rb'
require 'csv'

def multi_plot(chroms, titles, outdir, svg_name)
  # chroms and titles should be arrays
  # or define a data class chrom? Would actually be reusable?

  # create data table
  table = Array.new
  raise "mismatch length of chromatograms and titles!" if chroms.size != titles.size

  max_chrom_length = (chroms.max { |chrom| chrom[0].size })[0].size
  chroms.each_index do |i|
    table.push([titles[i]] + chroms[i][0] + ([''] * (max_chrom_length - chroms[i][0].size))) # Title - x values - blank filling to the max chrom length in this plot
    table.push([''] + chroms[i][1] + ([''] * (max_chrom_length - chroms[i][0].size))) # blank - y values - blank filling
  end
  table = table.transpose

  # create data csv for post-process
  csv_name = "#{outdir}/#{svg_name}.csv"
  fo = File.new(csv_name, "w")
  csv_out = CSV.new(fo)
  table.each do |row|
    csv_out << row
  end
  fo.close

  gnuplot_headder = <<~THE_END
    set datafile separator ','
    set terminal svg enhanced mouse jsdir '../js/'
  THE_END

  annotations = <<~THE_END
    set xlabel 'Retention time (min)' offset 0, 0.5
    set xtics nomirror out scale 0.5, 0.25
    set mxtics 10
    set yrange [-0.005:1.05]
    set ytics nomirror scale 0.5
    set ylabel 'Normalized ion counts' offset 2.5,0
    set y2tics scale 0.5
    set y2label 'Absorption (10^{-6} a.u.)' offset -2.5,0
    set terminal svg enhanced mouse jsdir '../js/' size 1200 600 font "Calibri, 16"
    set margins 5,9,2.5,0.5
    set linetype 1 lc rgb "black" lw 2
    set linetype 2 lc rgb "dark-red" lw 2
    set linetype 3 lc rgb "olive" lw 2
    set linetype 4 lc rgb "navy" lw 2
    set linetype 5 lc rgb "red" lw 2
    set linetype 6 lc rgb "dark-turquoise" lw 2
    set linetype 7 lc rgb "dark-blue" lw 2
    set linetype 8 lc rgb "dark-violet" lw 2
    set linetype cycle 8
    set output '#{outdir}/#{svg_name}.svg'
  THE_END

  # plot_line compilation
  plot_line = "plot '#{csv_name}'"
  raise if (table[0].size % 2) != 0

  i = 0
  while i < table[0].size
    plot_line += ", ''" if i > 0
    plot_line += " using #{i + 1}:#{i + 2} with lines t '#{titles[i / 2]}'"
    plot_line += " axis x1y2" if titles[i / 2] =~ /nm$/
    i += 2
  end

  temp_gnuplot = File.new("temp.gplot", "w")
  temp_gnuplot.puts gnuplot_headder
  #   temp_gnuplot.puts plot_line
  temp_gnuplot.puts annotations
  temp_gnuplot.puts plot_line
  temp_gnuplot.close

  result = `gnuplot temp.gplot`
  # result = `rm temp.gplot`
end

def spectrum_plot(spect, title, outdir, svg_name)
  # chroms and titles should be arrays
  # or define a data class chrom? Would actually be reusable?

  # create data table
  table = Array.new
  # chroms.each_index do |i|
  table.push([title] + spect[0])
  table.push([''] + spect[1])
  # end
  table = table.transpose

  # create data csv for post-process
  csv_name = "#{outdir}/#{svg_name}-#{title}.csv"
  fo = File.new(csv_name, "w")
  csv_out = CSV.new(fo)
  table.each do |row|
    csv_out << row
  end
  fo.close

  # Determine spectrum type from title (Yes this is stupid and undoing sth done I know...)
  if title =~ /ESI[\-\+]$/
    xlabel = "m/z"
    ylabel = "Ion counts"
  elsif title =~ /\-UV$/
    xlabel = "Wavelength (nm)"
    ylabel = "Accumulated absorption"
  else
    raise "This title shouldn't happen."
  end

  gnuplot_headder = <<~THE_END
    set datafile separator ','
    set terminal svg
  THE_END

  annotations = <<~THE_END
    set xlabel '#{xlabel}' offset 0, 0.5
    set xtics nomirror scale 0.5, 0.25
    set mxtics 10
    set ytics nomirror scale 0.5
    set ylabel '#{ylabel}' offset 3,0
    set terminal svg enhanced mouse jsdir '../js/' size 1200 600 font "Calibri, 16"
    set margins 9,3,2.5,0.5
    set output '#{outdir}/#{svg_name}.svg'
  THE_END

  # plot_line compilation
  plot_line = "plot '#{csv_name}'"
  plot_line += " using 1:2 with lines t '#{title}'"

  temp_gnuplot = File.new("temp.gplot", "w")
  temp_gnuplot.puts gnuplot_headder
  temp_gnuplot.puts annotations
  temp_gnuplot.puts plot_line
  temp_gnuplot.close

  result = `gnuplot temp.gplot`
  # result = `rm temp.gplot`
end

def report(raw, nickname, pick)
  # Generate of chromatograms and spectrums to generate from a line list.csv
  # This function should probably be renamed

  chroms = Array.new
  c_titles = Array.new
  spects = Array.new
  s_titles = Array.new

  if File.directory?(raw) == false
    # Fix: make exception
    puts "Path to raw data file \"#{raw}\" doesn't exist!"
    return nil, nil
  end

  # Parse and sort queries into query_list
  query_list = Array.new(4) { [Array.new, Array.new] }
  pick.each do |query|
    next if query == nil
    # If some query. magic regex lazy 1-liner, assignment also works as a nil check :p
    if qmatch = query.match(/^(\D+)?([\d\.]+)\s?(?:\-)?\s?([\d\.]+)?\s?(nm|\+|\-|min)$/)
      tolerance = 1.0 # Default spectral tolerance for spectra pick
      chrome_spect = 0 # Default: 0 for chromatogram, 1 for spectrum
      case qmatch[4] # which type of query?
      when "+" # ESI+
        funcnum = 1
      when "-" # ESI-
        funcnum = 2
      when "nm" # UV
        funcnum = 3
      when "min" 
        chrome_spect = 1 # Spectrum!
        tolerance = 0.05 # Default rt tolerance for time slice
        if qmatch[3] == nil # make range if no range was given
        start = qmatch[2].to_f - 0.5 * tolerance
          ending = start + tolerance
        else
          start, ending = qmatch[2..3].map { |s| s.to_f }.sort
        end
        case qmatch[1]
        when "+"
          funcnum = 1
        when "-"
          funcnum = 2
        when "uv"
          funcnum = 3
        when nil
          puts "No spectrum type specified! Plotting all three: ESI+, ESI- and UV."
          (1..3).each {|type| query_list[type][1].push [start, ending].sort}
          #query_list[2][1].push [start, ending].sort
          #query_list[3][1].push [start, ending].sort
          next
        # Early break for wildcard spectrum extraction. As long as it works...
        else
          puts "Query entry #{query} is problematic, skipped. #{qmatch}"
          next
        end
      end

      if qmatch[3] == nil # make range if no range was given. Should be the same as wildcard spectrum extraction case.
        start = qmatch[2].to_f - 0.5 * tolerance
        ending = start + tolerance
      else
        start, ending = qmatch[2..3].map { |s| s.to_f }.sort
      end
      query_list[funcnum][chrome_spect].push [start, ending].sort
    else
      puts "Query entry #{query} is problematic, skipped."
    end
  end

  puts "for file #{raw}"
  puts "UV: #{query_list[3]}"
  puts "ESI+: #{query_list[1]}"
  puts "ESI-: #{query_list[2]}"

  query_list[0..3].each_index do |i|
    #Real extraction of data
    next if query_list[i] == [[], []] # Decide if we need to open this ESI+/- or UV file. Saves time.

    puts "Opening raw file #{raw} function #{i}, nicknamed #{nickname}"
    func = MasslynxFunction.new(raw, i)

    query_list[i][0].each do |range| # Prepare extracted chromatogrames
      chrom = extract_chrom(func, range[0], range[1]).transpose
      y_f = chrom[1].map { |s| s.to_f }
      max_y = y_f.max
      chrom[1] = y_f.map { |y| y / max_y } if i < 3
      chroms.push chrom
      title = "#{nickname}: #{range[0]} - #{range[1]}"
      raise "wtf why can i == 0" if i == 0

      title += " + * #{"%.3e" % max_y}" if i == 1
      title += " - * #{"%.3e" % max_y}" if i == 2
      title += " nm" if i == 3
      c_titles.push title
    end

    query_list[i][1].each do |range| # Prepare time domain slice spectrum
      spect = spectrum_accum(func, range[0], range[1]).transpose
      y_f = spect[1].map { |s| s.to_f }
      # Normalization necessary?
      # max_y = y_f.max
      # spect[1] = y_f.map {|y| y/max_y} if i < 3
      spects.push spect
      title = "#{nickname}-#{range[0]}-#{range[1]}min"
      raise "wtf why can i == 0" if i == 0

      # title += " + * #{"%.3e" % max_y}" if i == 1
      title += "-ESI+" if i == 1
      title += "-ESI-" if i == 2
      title += "-UV" if i == 3
      s_titles.push title
    end
  end
  return chroms, c_titles, spects, s_titles
end

outdir = "Plot-#{Time.now.strftime("%d%b%Y-%k%M%S")}"
Dir.mkdir outdir
result = `cp list.csv #{outdir}/`

plot_list = Array.new
CSV.read("list.csv").each do |row|
  next if row[0] == 'path'
  plot_list.push([row[0], row[1], row[2..-1]])
end

chroms = Array.new
c_titles = Array.new
spects = Array.new
s_titles = Array.new

plot_list.each do |entry|
  new_chroms, new_c_titles, new_spects, new_s_titles = report(entry[0], entry[1], entry[2])
  chroms += new_chroms
  c_titles += new_c_titles
  spects += new_spects
  s_titles += new_s_titles
end

if !(chroms == nil || chroms == []) # If there are chromatograms to plot
  multi_plot(chroms, c_titles, outdir, "chromatograms") if !(chroms == nil || chroms == [])
end

if !(spects == nil || spects == []) # If there are spectra to plot
  spects.each_index do |i| # spectras are plotted separately
    # puts "s_titles are #{s_titles}"
    spectrum_plot(spects[i], s_titles[i], outdir, "#{s_titles[i]}")
  end
end
