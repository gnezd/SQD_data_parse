require './lib2.rb'

def xic(func, x_0, x_1)
    result = Array.new(func.size) {[0.0, 0.0]}
    (0..func.size-1).each do |scan| #each scan
        result[scan][0] = func.retention_time[scan]
        (0..func.spect[scan].size-1).each do |spect| #each spectral point
            next if func.spect[scan][spect] < x_0
            break if func.spect[scan][spect] > x_1
            result[scan][1] += func.counts[scan][spect]
        end
    end
    return result
end
raw = Masslynx_Function.new("raw/Bode - ycd2310on-1_20200604.raw", 2)
chrom = xic(raw, 246, 250)
puts chrom.class
puts chrom.size

fo = File.open("xic.tsv", "w")

chrom.each do |pt|
    fo.puts pt[0].to_s + "\t" + pt[1].to_s
end

fo.close

gnuplot_headder = <<THE_END
set terminal 'svg'
set output 'batch.svg'
set key outside bottom center

plot 'xic.tsv' with lines
THE_END

temp_gnuplot = File.new("temp.gplot", "w")
temp_gnuplot.puts gnuplot_headder
temp_gnuplot.close

result = `gnuplot temp.gplot`
result = `rm temp.gplot`