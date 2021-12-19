require './lib.rb'
require 'benchmark'
func1 = MasslynxFunction.new('./testdata/Bode - ycd2531-H1K1-1_20210921.raw', 2)
spect_ext1 = func1.extract_spect(3.72, 3.73).normalize
#spectra_plot([spect_ext1], './', 'spect1.svg')
func = MasslynxFunction.new('./testdata/Bode - ycd2531-TMX1-1_20210922.raw', 2)

Benchmark.bm do |benchmark|
  benchmark.report("Single") do
    pdct = Chromatogram.new(0, 'Picked', ['min', 'a.u.'])
    (0..func.retention_time.size-2).each do |i|
      spect = func.extract_spect(func.retention_time[i], (func.retention_time[i] + func.retention_time[i+1]) * 0.5)
      pdct.push [func.retention_time[i], spect * spect_ext1]
    end
    pdct.update_info
    #puts pdct.inspect
    chrom_plot([pdct], ['Picked'], '.', 'picked', 'true')
  end
  
  n = 2 # Number of threads
  benchmark.report("#{n}-thr") do
    pdct = Chromatogram.new(0, 'Picked', ['min', 'a.u.'])
    final_rt_index = func.retention_time.size-2
    index_per_thread = (final_rt_index / n).floor

    ths = []
    (0..n-1).each do |th|
      puts "Setting up thread #{th}, doing i being #{th*index_per_thread} to #{(th+1)*index_per_thread-1}"
    ths[th] = Thread.new do
    puts "Starting thread #{n} at #{Time.now}"
    (th*index_per_thread..(th+1)*index_per_thread-1).each do |i|
      break if i > final_rt_index
      spect = func.extract_spect(func.retention_time[i], (func.retention_time[i] + func.retention_time[i+1]) * 0.5)
      pdct[i] = [func.retention_time[i], spect * spect_ext1]
    end
    end
  end
    #ths.each {|th| th.join}
    ths[0].join
    ths[1].join
    pdct.update_info
    #puts pdct.inspect
    chrom_plot([pdct], ['Picked'], '.', 'picked', 'true')
  end
end
