#prototype multiple plot
require '../lib2.rb'
require 'csv'

def multi_plot(chroms, titles, outpath)
    #chroms and titles should be arrays
    #or define a data class chrom? Would actually be reusable?

    #create data table
    table = Array.new
    raise "mismatch length of chromatograms and titles!" if chroms.size != titles.size
    max_chrom_length = (chroms.max {|chrom| chrom[0].size})[0].size
    chroms.each_index do |i|
        table.push([titles[i]] + chroms[i][0]+ ([''] * (max_chrom_length - chroms[i][0].size)))
        table.push([''] + chroms[i][1] + ([''] * (max_chrom_length - chroms[i][0].size)))
    end
    table = table.transpose

    #create data csv for post-process
    csv_name = "#{outpath}(#{titles.size}).csv"
    fo = File.new(csv_name, "w")
    csv_out = CSV.new(fo)
    table.each do |row|
        csv_out << row
    end
    fo.close

    gnuplot_headder = <<THE_END
set datafile separator ','
set terminal svg
THE_END

annotations = <<THE_END
MAX=GPVAL_Y_MAX
MIN=GPVAL_Y_MIN
set yrange [MIN-(MAX-MIN)*0.05:MAX+(MAX-MIN)*0.05]
set xlabel 'Retention time (min)' offset 0, 0.5
set xtics nomirror scale 0.5, 0.25
set mxtics 10
set y2tics scale 0.5
set ytics nomirror scale 0.5
set ylabel 'Normalized ion counts' offset 2.5,0
set y2label 'Absorption (10^{-6} a.u.)' offset -2.5,0
set terminal svg enhanced mouse size 1200 600 font "Calibri, 16"
set margins 5,9,2.5,0.5
set output '#{outpath}'
THE_END

    #plot_line compilation
    plot_line = "plot '#{csv_name}'"
    raise if (table[0].size % 2) != 0
    i = 0
    while i < table[0].size
        plot_line += ", ''" if i > 0 
        plot_line += " using #{i+1}:#{i+2} with lines t '#{titles[i/2]}'"
        plot_line += " axis x1y2" if titles[i/2] =~ /nm$/
        i += 2
    end

    temp_gnuplot = File.new("temp.gplot", "w")
    temp_gnuplot.puts gnuplot_headder
    temp_gnuplot.puts plot_line
    temp_gnuplot.puts annotations
    temp_gnuplot.puts plot_line
    temp_gnuplot.close

    result = `gnuplot temp.gplot`
    #result = `rm temp.gplot`
end

def spectrum_plot(spect, title, outpath)
    #chroms and titles should be arrays
    #or define a data class chrom? Would actually be reusable?

    #create data table
    table = Array.new
    #chroms.each_index do |i|
        table.push([title] + spect[0])
        table.push([''] + spect[1])
    #end
    table = table.transpose

    #create data csv for post-process
    csv_name = "out/#{title}.csv"
    fo = File.new(csv_name, "w")
    csv_out = CSV.new(fo)
    table.each do |row|
        csv_out << row
    end
    fo.close

    #Determine spectrum type from title (Yes this is stupid and undoing sth done I know...)
    if title =~ /ESI[\-\+]$/
        xlabel = "m/z"
        ylabel = "Ion counts"
    elsif title =~ /\-UV$/
        xlabel = "Wavelength (nm)"
        ylabel = "Accumulated absorption"
    else
        raise "This title shouldn't happen."
    end

    gnuplot_headder = <<THE_END
set datafile separator ','
set terminal svg
THE_END

annotations = <<THE_END
set xlabel '#{xlabel}' offset 0, 0.5
set xtics nomirror scale 0.5, 0.25
set mxtics 10
set ytics nomirror scale 0.5
set ylabel '#{ylabel}' offset 3,0
set terminal svg enhanced mouse size 1200 600 font "Calibri, 16"
set margins 9,3,2.5,0.5
set output '#{outpath}'
THE_END

    #plot_line compilation
    plot_line = "plot '#{csv_name}'"
        plot_line += " using 1:2 with lines t '#{title}'"

    temp_gnuplot = File.new("temp.gplot", "w")
    temp_gnuplot.puts gnuplot_headder
    temp_gnuplot.puts annotations
    temp_gnuplot.puts plot_line
    temp_gnuplot.close

    result = `gnuplot temp.gplot`
    #result = `rm temp.gplot`
end

def report(raw, nickname, pick)

    chroms = Array.new
    c_titles = Array.new
    spects = Array.new
    s_titles = Array.new
    if File.directory?(raw) == false
        puts "Path to raw data file \"#{raw}\" doesn't exist!"
        return nil, nil
    end

    query_list = Array.new(4) {[Array.new, Array.new]}
    pick.each do |query|
        next if query == nil
        if qmatch = query.match(/^(\D+)?([\d\.]+)\s?(?:\-)?\s?([\d\.]+)?\s?(nm|\+|\-|min)$/)
            tolerance = 1.0 #Default spectral tolerance for spectra pick
            case qmatch[4] #which type of query?
            when "+"
                funcnum = 1
                xic_accu = 0
            when "-"
                funcnum = 2
                xic_accu =0
            when "nm"
                funcnum = 3
                xic_accu = 0
            when "min" #Spectrum!
                tolerance = 0.05 #Default rt tolerance for time slice
                xic_accu = 1
                case qmatch[1]
                when "+"
                    funcnum = 1
                when "-"
                    funcnum = 2
                when "uv"
                    funcnum = 3
                when nil
                    puts "No spectrum type specified! Plotting all three: ESI+, ESI- and UV."
                    #These are duplicated codes. I know it's ugly but I'm out of ideas for now...
                    if qmatch[3] == nil #make range if no range was given
                        start = qmatch[2].to_f-0.5*tolerance
                        ending = start + tolerance
                    else
                        start, ending = qmatch[2..3].map{|s| s.to_f}.sort
                    end
                    query_list[1][1].push [start, ending].sort
                    query_list[2][1].push [start, ending].sort
                    query_list[3][1].push [start, ending].sort
                    next
                    #As long as it works...  
                else
                    puts "Query entry #{query} is problematic, skipped. #{qmatch}"
                    next
                end
            end

            if qmatch[3] == nil #make range if no range was given
                start = qmatch[2].to_f-0.5*tolerance
                ending = start + tolerance
            else
                start, ending = qmatch[2..3].map{|s| s.to_f}.sort
            end

            query_list[funcnum][xic_accu].push [start, ending].sort
        else
            puts "Query entry #{query} is problematic, skipped."
        end
    end
    puts "for file #{raw}"
    puts "UV: #{query_list[3]}"
    puts "ESI+: #{query_list[1]}"
    puts "ESI-: #{query_list[2]}"

    query_list[0..3].each_index do |i|
        next if query_list[i] == [[],[]] #Decide if we need to open this ESI+/- or UV file. Saves time.
        puts "Opening raw file #{raw} function #{i}, nicknamed #{nickname}"
        func = Masslynx_Function.new(raw, i)

        query_list[i][0].each do |range| #Prepare extracted chromatogrames
            chrom = chromatogram_extract(func, range[0], range[1]).transpose
            y_f = chrom[1].map{|s| s.to_f}
            max_y = y_f.max
            chrom[1] = y_f.map {|y| y/max_y} if i < 3
            chroms.push chrom
            title = "#{nickname}: #{range[0]} - #{range[1]}"
            raise "wtf why can i == 0" if i == 0
            title += " + * #{"%.3e" % max_y}" if i == 1
            title += " - * #{"%.3e" % max_y}" if i == 2
            title += " nm" if i == 3
            c_titles.push title
        end
        
        query_list[i][1].each do |range| #Prepare time domain slice spectrum
            spect = spectrum_accum(func, range[0], range[1]).transpose
            y_f = spect[1].map{|s| s.to_f}
            #Normalization necessary?
            #max_y = y_f.max
            #spect[1] = y_f.map {|y| y/max_y} if i < 3
            spects.push spect
            title = "#{nickname}-#{range[0]}-#{range[1]}min"
            raise "wtf why can i == 0" if i == 0
            #title += " + * #{"%.3e" % max_y}" if i == 1
            title += "-ESI+" if i == 1
            title += "-ESI-" if i == 2
            title += "-UV" if i == 3
            s_titles.push title
        end
    end
    return chroms, c_titles, spects, s_titles
end

plot_list = Array.new
CSV.read("list.csv").each do |row|
    next if row[0] == 'name'
    plot_list.push([row[0], row[1], row[2..-1]])
end

plot_list.each do |entry|
    chroms, c_titles, spects, s_titles = report(entry[0], entry[1], entry[2])
    multi_plot(chroms, c_titles, "out/#{entry[1]}-chroms.svg") if !(chroms == nil || chroms == [])
    if !(spects == nil || spects == []) #If there are spectra to plot
        spects.each_index do |i|
            spectrum_plot(spects[i], s_titles[i], "out/#{entry[1]}-#{s_titles[i]}.svg")
        end
    end
end