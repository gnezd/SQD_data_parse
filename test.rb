#Test for refactoring lib.rb
require './lib.rb'
require 'benchmark'

time_load = Benchmark.measure do
puts "load func"
$func = Masslynx_Function.new('/Dropbox/Dropbox/LAb/Scripting field/Datacp/LCMS-Data/Bode - ycd2403tr-1548-1_20201109.raw', 3)
end
puts "scan index size: #{$func.scan_index.size}"
time_1st_ext = Benchmark.measure do
ext = $func.extract_chrom(200, 210)
end

time_2nd_ext = Benchmark.measure do
$ext = $func.extract_chrom(300, 310)
end

puts "Loading function: #{time_load}"
puts "1st extraction: #{time_1st_ext}"
puts "2nd extraction: #{time_2nd_ext}"

puts $ext