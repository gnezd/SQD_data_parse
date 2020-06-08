#prototype multiple plot
require './lib2.rb'

def multi_plot(chroms, titles, outpath)
    #chroms and titles should be arrays
    #or define a data class chrom? Would actually be reusable?
    gnuplot_headder = <<THE_END
set terminal svg enhanced mouse
set output '#{outpath}'
set key outside bottom center
THE_END
    plot_line = ""
    annotations = ""
    raise "mismatch length of chromatograms and titles!" if chroms.size != title.size

    #plot '#{title}.tsv' with lines t '#{title}'
    #THE_END

    temp_gnuplot = File.new("temp.gplot", "w")
    temp_gnuplot.puts gnuplot_headder
    temp_gnuplot.puts plot_line
    temp_gnuplot.puts annotations
    temp_gnuplot.close

    result = `gnuplot temp.gplot`
    result = `rm temp.gplot`
end