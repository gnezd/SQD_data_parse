#!/usr/bin/ruby

require 'time'

def display_bytes(str, delim)
	ret = Array.new
	str.each_byte do  |byte|
	ret.push ("%02X" % byte)
	end
return ret.join(delim)
end


