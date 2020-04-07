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

def bin_x(range, ms_func)

	range_begin, range_end, increment = range
    width = ((range_end-range_begin)/increment).ceil
    binned = Array.new(ms_func.spect.size) {Array.new(width) {0}}
    spect_value = [0] + (0..width).map {|x| range_begin+x*increment}
    (1..ms_func.size-1).each do |i|
        ms_func.spect[i].each_index do |spect|
            x = ((ms_func.spect[i][spect]-range_begin)/increment).ceil
            break if x > width-1
            next if x <= 0
            binned[i][x] += ms_func.counts[i][spect]
        end
	end
	
	return binned, spect_value
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
		@counts = Array.new(@size) {Array.new(0) {0}}
		@retention_time = Array.new(@size) {0.0}
		scan_num = 0
		while scan_num < @size
			scan_begin, scan_size, accumulate, rt = idx_raw[22*scan_num, 22].unpack("L S x x f f") 
			@retention_time[scan_num] = rt
			#extract DAT
			(0..scan_size-1).each do |spect|
				raw_count, byte3, raw_mcr, raw_mcr256 = dat_raw[scan_begin + spect*6, 6].unpack("s C C S")
				#count = raw_count * count_gain
				#mcr = mcr_multiplier * (rawmcr256/256+rawmcr)
				@spect[scan_num][spect] = ((2**((byte3/16).floor-7))*(raw_mcr256*256+raw_mcr)-46384).to_f/131034
				@counts[scan_num][spect] = raw_count * (4**(byte3 % 16))
			end
			scan_num += 1
		end
	end

	def inspect
		puts ""
	end

end