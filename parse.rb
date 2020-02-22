#!/usr/bin/ruby

require './lib.rb'

def unpack_general(data, cluster_size)
	result = []	
	(0..cluster_size-1).each do |x|
		break unless x < data.size 
		result.push data[x..x+3].unpack('S')[0].to_s
	end
	return result
end

def unpack_idx(line)
	result = Array.new
	result[0] = line[0..3].unpack('L')[0] #pointer to begin of scan
	
	result[1] = line[4..5].unpack('s')[0] #num of spectral points in this scan
	result[2] = line[12..15].unpack('f')[0] #retention time in miutes
	#result[16] = line[16..17].unpack('s')[0].to_s #max value in the scan
	return result

end

fname=ARGV[0]
fname_ext=fname.split('.')[-1]
cluster_size=ARGV[2].to_i
out_file = ARGV[3]

fin = File.open(fname+'.IDX', "rb")
#fo = File.open(ARGV[3], "w")
puts "Opening function #{fname}, and idx file size is #{fin.size}"



idx = fin.read
fin.close
ctr=0


accumulates = Hash.new(0)

scan_begin = []
scan_size = []
rt =[]

while ctr < idx.size-1
	unpacked = unpack_idx(idx[ctr..ctr+22])
	accumulates["points_from_IDX"] += unpacked[1].to_i
	scan_begin.push unpacked[0]
	scan_size.push unpacked[1]
	rt.push unpacked[2]
	ctr += 22
end


puts accumulates
puts scan_begin.size

fin = File.open(fname+".DAT", "rb")
dat = fin.read
scans = []

(0..3).each do |i|
	scans.push(dat[scan_begin[i]*6..(scan_begin[i]+scan_size[i])*6-1])
end

puts "For scan 0 it begins at #{scan_begin[0]} and spans #{scan_size[0]} 6X bytes"
(0..(scans[0].size)/6-1).each do |i|
	pt_str = scans[0][6*i..6*i+5]
	#puts "#{i}:\t|" + display_bytes(pt_str,'|') + "|\t" + pt_str[4..5].unpack('L')[0].to_s
	puts display_bytes(pt_str,' ') + "\t#{pt_str[0..1].unpack('S')[0]}\t#{pt_str[2].unpack('C')[0]}\t#{("\0"+pt_str[3..5]).unpack('L')[0]/256}"
end
