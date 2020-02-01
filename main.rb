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
formatted = Array.new
while ctr < data.size-1
	formatted.push(data[ctr..ctr+cluster_size-1])
	ctr += cluster_size
end

puts formatted.size

=begin
formatted.each do |line|
end
=end
line = formatted[50] # just a one-line example
puts display_bytes(line)

(0..11).each do |offset|

unpacked = line[offset..offset+3].unpack('l')[0]
puts ("  |"*offset.to_i)+unpacked.to_s

end

#1. trace back to absolute ptr pointing in data so unpack is complete when line changes
#2. more types
#3. select a segment of lines

fin.close
