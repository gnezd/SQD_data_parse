require './lib.rb'
func1 = MasslynxFunction.new('./testdata/Bode - ycd2531-H1K1-1_20210921.raw', 2)
spect_ext1 = func1.extract_spect(3.72, 3.73).normalize
#spectra_plot([spect_ext1], './', 'spect1.svg')
func = MasslynxFunction.new('./testdata/Bode - ycd2531-TMX1-1_20210922.raw', 2)
pdct = Chromatogram.new(0, 'Picked', ['min', 'a.u.'])
(0..func.retention_time.size-2).each do |i|
  spect = func.extract_spect(func.retention_time[i], (func.retention_time[i] + func.retention_time[i+1]) * 0.5)
  pdct.push [func.retention_time[i], spect * spect_ext1]
end
pdct.update_info
puts pdct.inspect
chrom_plot([pdct], ['Picked'], '.', 'picked', 'true')