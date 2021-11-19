require './lib.rb'
h = Isotopic_pattern.new
h[3] = 4
h[2] = 3
puts h
puts h[5]
h.assign({2=>1, 3=>2})
puts h
puts h[5]

func = MasslynxFunction.new('/mnt/g/Dropbox/LAb/After_departure/sep2021LCMS/Bode - ycd2531-H1K1-1_20210921.raw', 2)
spect_ext = func.extract_spect(3.72, 3.73)
