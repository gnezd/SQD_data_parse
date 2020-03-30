#!/usr/bin/ruby

require 'time'
require 'get_process_mem'

def display_bytes(str, delim)
	ret = Array.new
	str.each_byte do  |byte|
	ret.push ("%02X" % byte)
	end
return ret.join(delim)
end


class Masslynx_Function
	
	attr_reader :fname, :func_num, :size, :scans

	def initialize(fname, func_num)
	
		@fname = fname
		@func_num = func_num
		raw_in = File.open(fname + "/_FUNC00#{func_num}.DAT", "rb")
		dat_raw = raw_in.read
		raw_in.close
		idx_in = File.open(fname + "/_FUNC00#{func_num}.IDX", "rb")
		idx_raw = idx_in.read
		idx_in.close
		raise "#{fname}/_FUNC00#{func_num}.IDX corrupt" if idx_raw.size % 22 != 0
		@size = idx_raw.size / 22 #number of scan time points
		
		@scans = Array.new
		raw_size_chk = 0 #from IDX cross check
		scan_num = 0
		while scan_num < @size
			@scans.push(Masslynx_scan.new(idx_raw[22*scan_num..22*scan_num+21], dat_raw)) #build index
			raw_size_chk += @scans.last.size #accumulate number of total ms data points for cross check
			scan_num += 1
		end
		raise "Corupt #{fname}/_FUNC00#{func_num}.DAT file. Accumulative size should be 6 * #{raw_size_chk} = #{raw_size_chk*6} bytes but actually was #{dat_raw.size}" if dat_raw.size != 6* raw_size_chk

	end

	def inspect
		puts ""
	end

end

class Masslynx_scan
	attr_reader :idx_raw, :scan_begin, :size, :retention_time, :accumulate, :spectral_x, :count

	def initialize(idx_raw_22b, dat_raw)
		#process IDX
		@idx_raw = idx_raw_22b
		@scan_begin = @idx_raw[0..3].unpack('L')[0] #pointer to beginning of scan, in bytes
		@size = @idx_raw[4..5].unpack('S')[0] # size of scan, in 6B
		# 6..7 is still a mystery
		@accumulate = @idx_raw[8..11].unpack('f')[0]
		@retention_time = @idx_raw[12..15].unpack('f')[0]

		#process DAT
		@spectral_x = Array.new
		@count = Array.new

		dat_raw = dat_raw[@scan_begin..@scan_begin + @size*6] #chop in scan chunk
		
		counter = 0
		while counter < dat_raw.size - 1 #6B data point loop
			#prep and unpacks
			raw6b = dat_raw[counter..counter+5]
			raw_count = raw6b[0..1].unpack('s')[0]
			count_gain = 4**(raw6b[2].unpack('C')[0] % 16)
			mcr_multiplier = 2**((raw6b[2].unpack('C')[0]/16).floor-7)
			raw_mcr = ("\0"+raw6b[3..5]).unpack('L')[0]/256 #mcr = mass-charge ratio
			#real calc
			@count.push(raw_count * count_gain)
			@spectral_x.push((raw_mcr * mcr_multiplier - 46384).to_f / 131034) #131034 as slope and 46384 as intercept from emperical fitting. See note.md
			counter += 6
		end # end 6B data point loop
	end
end
