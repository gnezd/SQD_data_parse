# prototype multiple plot
require '../lib.rb'
require 'csv'
def report(raw, nickname, pick)
  # Generate of chromatograms and spectrums to generate from a line list.csv
  # This function should probably be renamed

  chroms = Array.new
  c_titles = Array.new
  ms_spects = Array.new
  uv_spects = Array.new
  
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
      
      # Debug dump of parsed queries      
      puts qmatch[1..4].join '|' if $debug == 1

      tolerance = 1.0 # Default spectral tolerance for spectra extraction
      chrome_spect = 0 # Default: 0 for chromatogram, 1 for spectrum

      case qmatch[4] # Which detector channel?
      when "+" # ESI+
        funcnum = 1
      when "-" # ESI-
        funcnum = 2
      when "nm" # UV
        funcnum = 3
      when "min" 
        # Spectrum!
        chrome_spect = 1
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

  puts "Queries on file #{raw}"
  puts "UV: #{query_list[3]}"
  puts "ESI+: #{query_list[1]}"
  puts "ESI-: #{query_list[2]}"

  query_list[0..3].each_index do |i|
    #Real extraction of data
    next if query_list[i] == [[], []] # Decide if we need to open this ESI+/- or UV file. Saves time.

    puts "Opening raw file #{raw} function #{i}, nicknamed #{nickname}"
    func = MasslynxFunction.new(raw, i)

    query_list[i][0].each do |range| # Prepare extracted chromatogrames
      chrom = func.extract_chrom(range[0], range[1])
      chrom.update_info
      max_y = chrom.signal_range[1]
      # Normalize XIC but not UV trace!
      if i == 1 || i == 2
        chroms.push chrom.normalize.transpose
      elsif i == 3
        chroms.push chrom.transpose
      end
      title = "#{nickname}: #{range[0]} - #{range[1]}"
      raise "wtf why can i == 0" if i == 0

      title += " + * #{"%.3e" % max_y}" if i == 1
      title += " - * #{"%.3e" % max_y}" if i == 2
      title += " nm" if i == 3
      c_titles.push title
    end

    query_list[i][1].each do |range| # Prepare time domain slice spectrum
      spect = func.extract_spect(range[0], range[1])
      spect.name = nickname + spect.name
      if func.func_num > 2
        uv_spects.push spect
      else
        ms_spects.push spect
      end
      raise "wtf why can i == 0" if i == 0
    end
  end
  return chroms, c_titles, ms_spects, uv_spects
end

# Begin main
listcsv = ARGV[0]
options = {}

if listcsv == nil 
  puts "Cannot find instruction from ARGV. Trying default: list.csv"
  listcsv = 'list.csv'
elsif !(File.exists?(listcsv))
  listcsv = 'list.csv'
  ARGV[0].split(',').each { |pair| options[pair.split('=')[0]] = pair.split('=')[1]}
else
  puts "Opening instruction file #{listcsv}"
  ARGV[1].split(',').each {|pair| options[pair.split('=')[0]] = pair.split('=')[1]} if ARGV[1]
end

puts options

outdir = "Plot-#{File.basename(listcsv, '.*')}-#{Time.now.strftime("%d%b%Y-%k%M%S")}"
Dir.mkdir outdir
result = `cp #{listcsv} #{outdir}/`

plot_list = Array.new
CSV.read(listcsv).each do |row|
  next if row[0] == 'path'
  plot_list.push([row[0], row[1], row[2..-1]])
end

chroms = Array.new
c_titles = Array.new
ms_spects = Array.new
uv_spects = Array.new

plot_list.each do |entry|
  new_chroms, new_c_titles, new_ms_spects, new_uv_spects = report(entry[0], entry[1], entry[2])
  chroms += new_chroms
  c_titles += new_c_titles
  ms_spects += new_ms_spects
  uv_spects += new_uv_spects
end

if !(chroms == nil || chroms == []) # If there are chromatograms to plot
  multi_plot(chroms, c_titles, outdir, "chromatograms") if !(chroms == nil || chroms == [])
end

if !(uv_spects == nil || uv_spects == []) # If there are spectra to plot
  spectra_plot(uv_spects, outdir, 'uv_spect',options['normalize_uv'])
end

if !(ms_spects == nil || ms_spects == []) # If there are spectra to plot
  spectra_plot(ms_spects, outdir, 'ms_spect', options['normalize_ms'])
end
