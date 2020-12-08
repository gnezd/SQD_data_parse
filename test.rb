# Test for refactoring lib.rb
require './lib.rb'
require 'benchmark'

time_load = Benchmark.measure do
  puts "load func"
  #$func = Masslynx_Function.new('/Dropbox/Dropbox/LAb/Scripting field/Datacp/LCMS-Data/Bode - ycd2403tr-1548-1_20201109.raw', 3)
  $func = MasslynxFunction.new('./raw/Bode - ycd20c29-2-7-1_20200315.raw', 2)
end
puts "scan index size: #{$func.scan_index.size}"
time_1st_ext = Benchmark.measure do
  $ext = $func.extract_chrom(200, 210)
end

time_2nd_ext = Benchmark.measure do
  $ext = $func.extract_spect(1, 1.1)
end
puts "--- Loading time benchmarks ---"
puts "Loading function: #{time_load}"
puts "1st extraction: #{time_1st_ext}"
puts "2nd extraction: #{time_2nd_ext}"

puts "--- Testing Chromatogram methods ---"
puts "Extracting 200 - 210 XIC"
chrom1 = $func.extract_chrom(200, 210)
puts "Computing derivative"
chrom2 = chrom1.deriv
puts "chrom1 size: #{chrom1.size}"
puts "chrom2 size: #{chrom2.size}"

multi_plot([chrom1.normalize.transpose, chrom2.normalize.transpose], ['chrom1', 'chrom2'], './', 'testplot')

puts "--- Testing sd_rank ---"
puts chrom1.sd_rank([3, 4], 0.5)/chrom1.signal_range[1]