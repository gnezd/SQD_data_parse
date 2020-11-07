#OBJ: compare two versions of function parsing to accelerate
load "./lib2.rb"
raise "Filename!" if ARGV[0] == nil
raw_name = ARGV[0]

puts "Constructing FUNCTIONS"

time_funcs = Benchmark.measure do
    $f1 = Masslynx_Function.new(raw_name, 1)
    $f2 = Masslynx_Function.new(raw_name, 2)
    $f3 = Masslynx_Function.new(raw_name, 3)
end

puts "Took #{time_funcs}"

#Matrix binning in spectral range!
time_smart_bin = Benchmark.measure do

    binned, spect_values = bin_x([200,1000,0.5], $f1)
    martrix_o = File.open("func1.csv", "w")
    martrix_o.puts spect_values.join ","
    binned.each_index do |row|
        martrix_o.puts $f1.retention_time[row].to_s + ', ' +binned[row].join(", ")
    end
    martrix_o.close
    
    binned, spect_values = bin_x([200,1000,0.5], $f2)
    martrix_o = File.open("func2.csv", "w")
    martrix_o.puts spect_values.join ","
    binned.each_index do |row|
        martrix_o.puts $f2.retention_time[row].to_s + ', ' +binned[row].join(", ")
    end
    martrix_o.close

    binned, spect_values = bin_x([210, 600, 1], $f3)
    martrix_o = File.open("func3.csv", "w")
    martrix_o.puts spect_values.join ","
    binned.each_index do |row|
        martrix_o.puts $f3.retention_time[row].to_s + ', ' +binned[row].join(", ")
    end
    martrix_o.close
end
puts "Smart binning took: #{time_smart_bin}"
#=end

mem = GetProcessMem.new
puts "Memory usage: #{mem.mb}"