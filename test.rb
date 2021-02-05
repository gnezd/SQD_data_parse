require './lib.rb'
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

puts "Now testing Masslynxfunction.extract_spect"

msl = MasslynxFunction.new('raw/Bode - ycd20c29-2-7mid-1_20200315.raw', 2)
spe = msl.extract_spect(2.5, 2.6)