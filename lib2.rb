#!/usr/bin/ruby

require 'time'
require 'get_process_mem'
require 'benchmark'

def display_bytes(str, delim)
	ret = Array.new
	str.each_byte do  |byte|
	ret.push ("%02X" % byte)
	end
return ret.join(delim)
end


class Masslynx_Function
	
	attr_reader :fname, :func_num, :size, :spect, :counts, :retention_time

	def initialize(fname, func_num)
	
		@fname = fname
		@func_num = func_num
		raw_in = File.open(fname + "/_FUNC00#{func_num}.DAT", "rb")
		dat_raw = raw_in.read.freeze
		raw_in.close
		idx_in = File.open(fname + "/_FUNC00#{func_num}.IDX", "rb")
		idx_raw = idx_in.read.freeze
		idx_in.close
		raise "#{fname}/_FUNC00#{func_num}.IDX corrupt" if idx_raw.size % 22 != 0
		@size = idx_raw.size / 22 #number of scan time points
		
		@spect = Array.new(@size) {Array.new() {0.0}}
		@counts = Array.new(@size) {Array.new(2500) {0}}
		@retention_time = Array.new(@size) {0.0}
		raw_size_chk = 0 #from IDX cross check
		scan_num = 0
		while scan_num < @size
			scan_begin, scan_size, accumulate, rt = idx_raw[22*scan_num, 22].unpack("L S x x f f") 
			@retention_time[scan_num] = rt
			raw_size_chk += scan_size #accumulate number of total ms data points for cross check
			
			#extract DAT
			(0..scan_size-1).each do |spect|
				raw_count, byte3, raw_mcr, raw_mcr256 = dat_raw[scan_begin + spect*6, 6].unpack("s C C S")
				#count = raw_count * count_gain
				#mcr = mcr_multiplier * (rawmcr256/256+rawmcr)
#				@scans[scan_num][spect] = [((2**((byte3/16).floor-7))*(raw_mcr256*256+raw_mcr)-46384)/131034, raw_count * (4**(byte3 % 16))]
				@spect[scan_num][spect] = ((2**((byte3/16).floor-7))*(raw_mcr256*256+raw_mcr)-46384).to_f/131034
				@counts[scan_num][spect] = raw_count * (4**(byte3 % 16))
			end
			scan_num += 1
		end
=begin
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
=end
	end

	def inspect
		puts ""
	end

end

class Masslynx_scan
	attr_reader :idx_raw, :scan_begin, :size, :retention_time, :accumulate, :spectral_x, :count

	def initialize(idx_raw_22b, dat_raw)
		#process IDX

		#process DAT
		@spectral_x = Array.new
		@count = Array.new

		dat_raw = dat_raw[@scan_begin..@scan_begin + @size*6] #chop in scan chunk
		
	end
end
