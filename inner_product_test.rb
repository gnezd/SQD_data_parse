require './lib.rb'
unity = Spectrum.new('Function x', 'Arb int')
[[0.0, 1.0], [1.0, 1.0]].each {|pt| unity.push pt}
sin = Spectrum.new 'Sin', 'Arb'
cos = Spectrum.new 'Cos', 'Arb'
sampling_rate = 1000.0

(0..sampling_rate.to_i).each do |s|
    t = s + rand / 10 / sampling_rate
  sin.push [t / sampling_rate, Math.sin(t * 3.14/sampling_rate)]
    t = s + rand / 10 / sampling_rate
  cos.push [t / sampling_rate, Math.cos(t * 3.14 /sampling_rate)]
end
puts "Testing of inner product defined at [0,1]. Sampling rate: #{sampling_rate}"
puts "<sin, cos>: #{sin * cos}"
puts "<sin, sin>: #{sin * sin}"
puts "<cos, cos>: #{cos * cos}"
puts "<1, sin>: #{unity * sin}"
puts "<1, cos>: #{unity * cos}"

func = MasslynxFunction.new('./testdata/Bode - ycd2531-H1K1-1_20210921.raw', 2)

spect_ext1 = func.extract_spect(3.72, 3.73)
spect_ext2 = func.extract_spect(3.73, 3.74)

puts spect_ext1 * spect_ext1
puts spect_ext1 * spect_ext2
puts spect_ext2 * spect_ext1
puts spect_ext2 * spect_ext2