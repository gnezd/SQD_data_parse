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
    puts max_chrom_length
    puts max_chrom_length.class
    chroms.each_index do |i|
        table.push([titles[i]] + chroms[i][0]+ ([''] * (max_chrom_length - chroms[i][0].size)))
        table.push([''] + chroms[i][1] + ([''] * (max_chrom_length - chroms[i][0].size)))
    end
    table = table.transpose

    #create data csv for post-process
    csv_name = "#{titles[0]}(#{titles.size}).csv"
    fo = File.new(csv_name, "w")
    csv_out = CSV.new(fo)
    table.each do |row|
        csv_out << row
    end
    fo.close

    gnuplot_headder = <<THE_END
set datafile separator ','
set terminal svg enhanced mouse
set output '#{outpath}'
set key outside bottom center
THE_END

    #plot_line compilation
    plot_line = "plot '#{csv_name}'"
    raise if (table[0].size % 2) != 0
    i = 0
    while i < table[0].size
        plot_line += ", ''" if i > 0 
        plot_line += " using #{i+1}:#{i+2} with lines"
        i += 2
    end
    annotations = ""

    #plot '#{title}.tsv' with lines t '#{title}'
    #THE_END

    temp_gnuplot = File.new("temp.gplot", "w")
    temp_gnuplot.puts gnuplot_headder
    temp_gnuplot.puts plot_line
    temp_gnuplot.puts annotations
    temp_gnuplot.close

    result = `gnuplot temp.gplot`
    #result = `rm temp.gplot`
end

chrom1 = [[0, 1, 2], [1,2,3]]
chrom2 = [[0,1,2,3], [2,4,6,8]]

multi_plot([chrom1,chrom2], ['chrom1', 'chrom2'], 'test.svg')