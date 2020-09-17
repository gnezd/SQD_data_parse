require '../lib2.rb'
require 'csv'
#require 'pty'
#require 'tk'

def datatable(chroms, titles)
    #Create 2d array of chromatograms, fill blanks and trnapose for CSV output
    table = Array.new
    raise "mismatch length of chromatograms and titles!" if chroms.size != titles.size
    max_chrom_length = (chroms.max {|chroma, chromb| chroma[0].size <=> chromb[0].size})[0].size
    chroms.each_index do |i|
        table.push([titles[i]] + chroms[i][0]+ ([''] * (max_chrom_length - chroms[i][0].size))) #Title - x values - blank filling to the max chrom length in this plot
        table.push([''] + chroms[i][1] + ([''] * (max_chrom_length - chroms[i][0].size))) # blank - y values - blank filling
    end
    table = table.transpose
    return table
end
def normalize(chrom)
    #Divide all by max
    max = chrom.max_by{|pta| pt[1].abs}[1].abs
    norm = chrom.map {|pt| [pt[0], pt[1]/max]}
    return norm, max
end
def deriv(chrom)
    #Simple derivative
    d = Array.new
    chrom.each_index do |i|
        next if i == 0
        x = (chrom[i][0]+chrom[i-1][0])/2
        y = (chrom[i][1]-chrom[i-1][1])/(chrom[i][0]-chrom[i-1][0])
        d.push [x, y]
    end
    return d
end

def ma(chrom, radius)
    #+- radius points moving average
    a = Array.new
    chrom.each_index do |i|
        y = 0.0
        next if (i-radius < 0) || (i+radius) > chrom.size-1
        x = chrom[i][0]
        (i-radius..i+radius).each do |ii| #second index for summation. Feels slow with this dbl loop but... whatever for now
           # puts "i is #{i} and ii is #{ii}"
            y += chrom[ii][1]
        end
        y = y/(2*radius+1)
        a.push [x,y]
    end
    return a
end

def max_neighborhood(chrom, exclude, r, &crit)
    #check if that max is in the exclusion zone, do another if so...?
    #No. First generate complementary of exclusion zone and enumerate through all maxes
    #And then pick out the maxest one
    #Integrate exclusion zone
    #return
    pt = chrom.max{crit}
    return pt, upd_exclude
end
#extract a chromatogram and plot interactively
raw = "../raw/Bode - ycd2310on-1_20200604.raw"
#func = Masslynx_Function.new(raw, 2)
#tic = chromatogram_extract(func, 200, 500)
#fo = File.new("peak_test_chrom.csv", "w")
#csv_out = CSV.new(fo)
#tic.each do |row|
#    csv_out << row
#end

#read raw chrom in
chrom = Array.new
titled = 0 #no title in the csv
csv_in = CSV.read("chrom0.csv")
chrom_name = (csvin.shift)[0] if titled == 1
csv_in.each do |pt|
    chrom.push pt.map {|x| x.to_f}
end

ma3 = ma(chrom, 1)
deriv, deriv_i = normalize(deriv(chrom))
derivma, derivma_i = normalize(deriv(ma3))
deriv2, int = normalize(deriv(derivma))


titles = ['orig',  "deriv_#{"%.2f" % Math.log10(deriv_i)}_n", 'deriv2_n']
chroms = Array.new
chroms.push chrom.transpose
#chroms.push ma3.transpose
chroms.push deriv.transpose
#chroms.push derivma.transpose
chroms.push deriv2.transpose

peaks = Array.new
#puts "size of neg 2 deriv2: #{neg5_deriv2}"
annotate_out = File.new("peaks.csv", "w")
csv_ann = CSV.new(annotate_out)
peaks.each do |dot|
    csv_ann << dot
end
annotate_out.close

table = datatable(chroms, titles)
fo = File.new("table.csv", "w")
csv_out = CSV.new(fo)
table.each do |row|
    csv_out << row
end
fo.close
#set terminal tkcanvas ruby interactive
gnuplot_head = <<THE_END
set terminal svg enhanced mouse size 1000 600
set output 'blah.svg'
set datafile separator ','
set xlabel 'rt'
set xtics nomirror out scale 0.5, 0.25
set mxtics 10
set ytics nomirror scale 0.5
set y2tics
set y2range [-1.1:1.1]
THE_END

temp_gnuplot = File.new("pktemp.gp", "w")
temp_gnuplot.puts gnuplot_head

plot_line = "plot 'table.csv'"
titles.each_index do |chrom_num|
    plot_line += ", ''" if chrom_num > 0
    plot_line += " using #{chrom_num*2+1}:#{chrom_num*2+2} with lines t '#{titles[chrom_num].gsub('_','\_')}'"
    plot_line += " axis x1y2" if titles[chrom_num] =~ /\_n$/
end
plot_line += ", 'peaks.csv' using 1:2:('x') with labels axis x1y2"
temp_gnuplot.puts plot_line
temp_gnuplot.close
#result = `gnuplot pktemp.gp > canvas_out.rb`
result = `gnuplot pktemp.gp`
puts result
result = `open blah.svg`
#root = TkRoot.new {title 'Ruby/Tk'}
#c = TkCanvas.new(root, 'width'=> 800, 'height'=>600) {pack {}}
#load('canvas_out.rb')
#gnuplot(c)
#Tk.mainloop