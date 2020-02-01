#!/usr/bin/ruby

require 'time'

def display_bytes(str)
	ret = String.new
	str.each_byte do  |byte|
	ret += "%02X|" % byte
	end
return ret
end


