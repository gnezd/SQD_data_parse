#!/usr/bin/ruby

require 'time'

def display_bytes(str, delim)
	ret = String.new
	str.each_byte do  |byte|
	ret += "%02X#{delim}" % byte
	end
return ret
end


