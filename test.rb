#Test for refactoring lib.rb
require './lib.rb'
require 'benchmark'

time_load = Benchmark.measure do
puts "load func"
$func = Masslynx_Function.new('./raw/2331/Bode - ycd2331-1-1_20200708.raw', 3)
end
puts "scan index size: #{$func.scan_index.size}"
time_1st_ext = Benchmark.measure do
ext = $func.extract(200, 210)
end

time_2nd_ext = Benchmark.measure do
$ext = $func.extract(300, 310)
end

puts "Loading function: #{time_load}"
puts "1st extraction: #{time_1st_ext}"
puts "2nd extraction: #{time_2nd_ext}"

puts $ext