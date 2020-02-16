#!/usr/bin/ruby

require './lib.rb'

fname=ARGV[0]
index_match=ARGV[1].match(/^(\d+)?(\-)?(\d+)?$/)
cluster_size=ARGV[2].to_i
out_file = ARGV[3]

fin = File.open(fname, "rb")
fo = File.open(ARGV[3], "w")
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
output =<<STYLE
<head>
<link rel="stylesheet" type="text/css" href="view.css">
</head>
<table>
STYLE

fo.puts output

while ctr <= data.size-1
	puts ctr
	tdline = "<tr class=\"binsrc\"><td class=\"addr\" rowspan=2><span class=\"addr-dec\">#{ctr}</span><br><span class=\"addr-hex\">#{"%02x" % ctr}</span></td><td class=\"binsrc\">"
	tdline +=  display_bytes(data[ctr..ctr+cluster_size-1], "</td><td class=\"binsrc\">")
	tdline +="</td></tr>\n<tr class=\"intptd\"><td class=\"intptd\">"
	unpacked = []
	(0..cluster_size-1).each do |x|
		break unless x+ctr < data.size 
		unpacked.push data[ctr+x..ctr+x+3].unpack('C')[0]
	end
	tdline += unpacked.join("</td><td class=\"intptd\">")
	tdline += "</td></tr>\n"
	fo.puts tdline
	ctr += cluster_size
end

fo.puts "</table>"
fo.close
fin.close
