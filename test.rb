#OBJ: compare two versions of function parsing to accelerate
require "./lib.rb"

raw_name = ARGV[0]

puts "Benchmarking constructing FUNC1"

time_per_func = Benchmark.measure do
    $f1 = Masslynx_Function.new(raw_name, 3)
end

puts "Took #{time_per_func}"


#Matrix binning in spectral range!

#scan_ext = [$f1.scans[100], $f1.scans[200], $f1.scans[300]] # to make dev test faster
scan_ext = $f1.scans
xrange = [180, 610, 0.5]
binned = Array.new(scan_ext.size) {Array.new} 
bin = 0


scan_ext.each_index do |i|
    puts "binning scan #{i}"
    binned[i][0] = scan_ext[i].retention_time
    x = xrange[0]
    while x < xrange[1]
        scan_ext[i].spectral_x.each_index do |spect| #iterate spectral point
            if scan_ext[i].spectral_x[spect] >= (x + xrange[2])
                puts "break! i=#{i} at x = #{x} becaus #{scan_ext[i].spectral_x[spect]} exceeded #{x + xrange[2]}"
                x += xrange[2] #iterate x frame before break!
                break
            end
           if scan_ext[i].spectral_x[spect] >= x
               bin += scan_ext[i].count[spect] 
               puts "bin! #{i}"
           end
        end #end spectral iteration
        x += xrange[2]
        binned[i].push bin
        bin = 0        
    end
end

martrix_o = File.open("matrix.csv", "w")
binned.each do |row|
    martrix_o.puts row.join(", ")
end

mem = GetProcessMem.new
puts mem.mb