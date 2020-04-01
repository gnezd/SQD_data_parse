#!/usr/bin/ruby
#Usage: <this.rb> file_name index group_size output
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
	result = Array.new(22, '-')
	result[0] = line[0..3].unpack('L')[0].to_s #pointer to begin of scan
	result[1..3] = ["","",""]
	
	result[4] = line[4..5].unpack('s')[0].to_s #num of spectral points in this scan
	result[5] = ""
	result[6] = line[6..7].unpack('s')[0].to_s #00-18
	result[7] = ""
	result[8] = line[8..11].unpack('f')[0].to_s #Accumulative signal?
	result[9..11] = ["", "", ""]
	result[12] = line[12..15].unpack('f')[0].to_s #retention time in miutes
	result[13..15] = ["", "", ""]
	result[16] = line[16..17].unpack('s')[0].to_s #max value in the scan
	result[17] = ""
	result[18] = line[18..21].unpack('L')[0].to_s #??
	result[19..21] = ["", "", ""]
	return result

end

fname=ARGV[0]
fname_ext=fname.split('.')[-1]
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
fin.close
ctr=0
output =<<STYLE
<head>
<link rel="stylesheet" type="text/css" href="view.css">
</head>
<table>
STYLE

fo.puts output

accumulates = Hash.new(0)

while ctr <= data.size-1
	tdline = "<tr class=\"binsrc\"><td class=\"addr\" rowspan=2><span class=\"addr-dec\">#{ctr}</span><br><span class=\"addr-hex\">#{"%02x" % ctr}</span></td><td class=\"binsrc\">"
	tdline +=  display_bytes(data[ctr..ctr+cluster_size-1], "</td><td class=\"binsrc\">")
	tdline +="</td></tr>\n<tr class=\"intptd\"><td class=\"intptd_std\">"
	if fname_ext == "IDX"
		unpacked = unpack_idx(data[ctr..ctr+22])
		accumulates["points_from_IDS"] += unpacked[4].to_i
	else
		unpacked = unpack_general(data[ctr..ctr+cluster_size+3], cluster_size)
	end
	tdline += unpacked[0..3].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[4..5].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[6..7].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[8..11].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[12..15].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[16..17].join("</td><td class=\"intptd\">") + "<td class=\"intptd_std\">"
	tdline += unpacked[18..21].join("</td><td class=\"intptd\">")
	tdline += "</td></tr>\n"
	fo.puts tdline
	ctr += cluster_size
end

fo.puts "</table>"
fo.close

puts accumulates