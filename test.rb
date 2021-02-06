require './lib.rb'
puts ARGV
=begin
spe = Spectrum.new('aa', 'nounit')
spe.push [0.0, 1.1]
spe.push [2.2, 3.1]

puts "Before info update"
puts spe.inspect

spe.update_info

puts "After info update:"
puts spe.inspect
puts "Dumping content:"
spe.each {|i| puts i.join('|')}
puts "Using map:"
puts spe.map {|pt| pt.join '|'}
puts "Transpose:"
spe.transpose.each {|i| puts i.join '|'}


# Manual plotting test
csvout = File.open('test.csv', 'w')
csv_out = CSV.new csvout
spe.each do |row|
    csv_out << row
end
csvout.close
gplot_out = File.open('test.gplot', 'w')
gplot_out.puts "
set datafile separator ','
set terminal svg
set output 'test.svg'
plot 'test.csv' with lines
"
gplot_out.close

puts `#{which('gnuplot')} test.gplot`
=end

puts "Now testing Masslynxfunction.extract_spect"

msl = MasslynxFunction.new('raw/Bode - ycd20c29-2-7mid-1_20200315.raw', 2)
spe = msl.extract_spect(2.5, 2.6)
spe2 = MasslynxFunction.new('raw/Bode - ycd20c29-2-7mid-1_20200315.raw', 1).extract_spect(3.1, 3.5)
spectra_plot([spe, spe2], '.', 'spectra')
spectra_plot([spe, spe2], '.', 'spectranormalized', 'true')