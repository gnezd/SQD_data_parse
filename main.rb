#!/usr/bin/ruby

require './lib.rb'

fname=ARGV[0]
n_bytes=ARGV[1].to_i
cluster_size=ARGV[2].to_i

puts "Opening file \"#{fname}\", and listing #{n_bytes} bytes with #{cluster_size} bytes per line"
fin = File.open(fname, "rb")


puts "File size is #{fin.size}"
data = fin.read[0..n_bytes-1]
ctr=0

while ctr < data.size-1
	puts display_bytes(data[ctr..ctr+cluster_size-1])
	(0..cluster_size-1).each do |x|
		unpacked = data[ctr+x..ctr+x+3].unpack('C')[0]
		puts ("  |"*x)+unpacked.to_s
		#puts ("   "*x)+display_bytes(data[ctr+x..ctr+x+3])
	end


	ctr += cluster_size
end


=begin
(0..11).each do |offset|

unpacked = line[offset..offset+3].unpack('l')[0]
puts ("  |"*offset.to_i)+unpacked.to_s

end
=end

#1. trace back to absolute ptr pointing in data so unpack is complete when line changes
#2. more types
#3. select a segment of lines

fin.close
