#!/usr/bin/ruby

require './lib.rb'

fname=ARGV[0]
index_match=ARGV[1].match(/^(\d+)?(\-)?(\d+)?$/)
cluster_size=ARGV[2].to_i

fin = File.open(fname, "rb")
fo = File.open("output.html", "w")
puts "Opening file #{fname}, and File size is #{fin.size}"

if index_match[2]
	puts "ranged index"
	index_begin = index_match[1].to_i
	if index_match[3]
		index_end = index_match[3].to_i
	else
		index_end = fin.size-1
	end
elsif index_match[1]
	index_begin = 0
	index_end = index_match[1].to_i-1
else
	raise "Wrong index/index range!"
end



puts "Listing #{index_end - index_begin+1} bytes from #{index_begin} to #{index_end} with #{cluster_size} bytes per line"


data = fin.read[index_begin..index_end]
ctr=0
fo.puts "<table>"

while ctr <= data.size-1
	puts ctr
	tdline = "<tr><td>"
	tdline +=  display_bytes(data[ctr..ctr+cluster_size-1], "</td><td>")
	tdline +="</td></tr>\n<tr><td>"
	(0..cluster_size-1).each do |x|
		unpacked = data[ctr+x..ctr+x+3].unpack('C')[0]
		tdline+= unpacked.to_s + "</td><td>"
		#puts ("   "*x)+display_bytes(data[ctr+x..ctr+x+3])
	end
	tdline += "</td></tr>\n"
	fo.puts tdline
	ctr += cluster_size
end

fo.puts "</table>"
fo.close
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
