#OBJ: compare two versions of function parsing to accelerate
load "./lib2.rb"
raise "Filename!" if ARGV[0] == nil
raw_name = ARGV[0]

puts "Constructing FUNCTIONS"
f1 = Masslynx_Function.new(raw_name, 1)
f2 = Masslynx_Function.new(raw_name, 2)
f3 = Masslynx_Function.new(raw_name, 3)
#Matrix binning in spectral range!
mid_mass_range = [200, 1000, 1]
low_mass_range = [100, 500, 1]
uv_range = [210, 600, 1]
matrix_o = File.open("Plotly_test/data.js", "w")
binned, spect_values = bin_x(low_mass_range , f1)
matrix_o.puts "f1 = "
matrix_o.puts (binned.inspect)+";" 

binned, spect_values = bin_x(low_mass_range, f2)
matrix_o.puts "f2 = "
matrix_o.puts (binned.inspect)+";" 

binned, spect_values = bin_x(uv_range, f3)
matrix_o.puts "f3 = "
matrix_o.puts (binned[150..-1].inspect)+";" 
matrix_o.close


mem = GetProcessMem.new
puts "Memory usage: #{mem.mb}"