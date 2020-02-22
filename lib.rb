#!/usr/bin/ruby

require 'time'

def display_bytes(str, delim)
	ret = Array.new
	str.each_byte do  |byte|
	ret.push ("%02X" % byte)
	end
return ret.join(delim)
end

def unpack_idx(line)
	result = Array.new
	result[0] = line[0..3].unpack('L')[0] #pointer to begin of scan
	
	result[1] = line[4..5].unpack('s')[0] #num of spectral points in this scan
	result[2] = line[12..15].unpack('f')[0] #retention time in miutes
	return result

end

