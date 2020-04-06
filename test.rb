#OBJ: compare two versions of function parsing to accelerate
load "./lib2.rb"
raise "Filename!" if ARGV[0] == nil
raw_name = ARGV[0]

puts "Constructing FUNC1"

time_per_func = Benchmark.measure do
    $f1 = Masslynx_Function.new(raw_name, 1)
end

puts "Took #{time_per_func}"

fo = File.new "output", "w"
fo.puts $f1.retention_time
fo.close
#Matrix binning in spectral range!

#scan_ext = [$f1.scans[100], $f1.scans[200], $f1.scans[300]] # to make dev test faster
xrange = [100, 500, 0.5]
=begin
binned = Array.new(scan_ext.size) {Array.new} 
bin = 0
time_stupid_bin = Benchmark.measure do
    scan_ext.each_index do |i|
        #puts "binning scan #{i}"
        binned[i][0] = scan_ext[i].retention_time
        x = xrange[0]
        while x < xrange[1]
            scan_ext[i].spectral_x.each_index do |spect| #iterate spectral point
                if scan_ext[i].spectral_x[spect] >= (x + xrange[2])
                    #puts "break! i=#{i} at x = #{x} becaus #{scan_ext[i].spectral_x[spect]} exceeded #{x + xrange[2]}"
                    x += xrange[2] #iterate x frame before break!
                    break
                end
            if scan_ext[i].spectral_x[spect] >= x
                bin += scan_ext[i].count[spect] 
                #puts "bin! #{i}"
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
    martrix_o.close
end
puts "Stupid binning took: #{time_stupid_bin}"
=end
#=begin
time_smart_bin = Benchmark.measure do
    width = ((xrange[1]-xrange[0])/xrange[2]).ceil
    binned = Array.new($f1.spect.size) {Array.new(width) {0}}
    binned[0]= [0] + (0..width).map {|x| xrange[0]+x*xrange[2]}
    (1..$f1.size-1).each do |i|
        $f1.spect[i].each_index do |spect|
            x = (($f1.spect[i][spect]-xrange[0])/xrange[2]).ceil
            break if x > width-1
            next if x <= 0
            binned[i][x] += $f1.counts[i][spect]
        end
    end
    martrix_o = File.open("matrix_smart.csv", "w")
    binned.each do |row|
        martrix_o.puts row.join(", ")
    end
    martrix_o.close
end
puts "Smart binning took: #{time_smart_bin}"
#=end

mem = GetProcessMem.new
puts "Memory usage: #{mem.mb}"