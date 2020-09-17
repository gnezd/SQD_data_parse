#!/usr/bin/ruby
#Main library for Waters SQD data parsing
#Requirement: gnuplot
#Content: Class definition of Masslynx_Function
#And some orphan functions: display_bytes(), bin_x(), chromatogram_extract(), spectrum() and plot()

#require 'time'
#require 'get_process_mem'
#require 'benchmark'

class Masslynx_Function
	
	attr_reader :fname, :func_num, :size, :spect, :counts, :retention_time, :total_trace

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
		@total_trace = Array.new(@size) {0.0}
		
		scan_num = 0
		while scan_num < @size
			scan_begin, scan_size, accumulate, rt = idx_raw[22*scan_num, 22].unpack("L S x x f f") 
			#info from IDX
			@retention_time[scan_num] = rt
			@total_trace[scan_num] = accumulate
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

def display_bytes(str, delim) #Bytewise show string in hex with deliminator
	ret = Array.new
	str.each_byte do  |byte|
	ret.push ("%02X" % byte)
	end
return ret.join(delim)
end

def bin_x(range, ms_func) #Bin the spectral domain of a Masslynx_Function io designated range and resolution

	range_begin, range_end, increment = range
    width = ((range_end-range_begin)/increment).ceil
    binned = Array.new(ms_func.spect.size) {Array.new(width) {0}}
    spect_value = [''] + (0..width).map {|x| range_begin+x*increment}
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

def chromatogram_extract(func, x_0, x_1) #Extract chromatogram in given spectral range (inclusive)
    result = Array.new(func.size) {[0.0, 0.0]}
    (0..func.size-1).each do |scan| #each scan
		result[scan][0] = func.retention_time[scan]
		spectral_width = 0 #for normalizing UV abs
        (0..func.spect[scan].size-1).each do |spect| #each spectral point
            next if func.spect[scan][spect] < x_0
			break if func.spect[scan][spect] > x_1
			spectral_width += 1
            result[scan][1] += func.counts[scan][spect]
		end
		if func.func_num == 3
			#puts "UV, normalizing"
			result[scan][1] = result[scan][1].to_f / spectral_width 
		end
	end
	
    return result
end

def spectrum_accum(func, t_0, t_1) #Sum up mass spectra over given retention time range (inclusive)
	sum = Hash.new {0}
	#chrom_width = 0 #for UV normalization
	#DANGER of NOT binning and normalizing!!!!! (03 Jul 2020)
    (0..func.size-1).each do |scan|
        next if func.retention_time[scan] < t_0
		break if func.retention_time[scan] > t_1
		#chrom_width += 1
        (0..func.spect[scan].size-1).each do |sp|
            sum[func.spect[scan][sp]] += func.counts[scan][sp]
        end
    end
    return sum.sort.to_a
end

def plot(data, title, outpath) #Plot xy function with title with gnuplot
    fo = File.open("#{title}.tsv", "w")
    data.each do |pt|
        fo.puts pt[0].to_s + "\t" + pt[1].to_s
    end
    fo.close

    gnuplot_headder = <<THE_END
set terminal svg enhanced mouse
set output '#{outpath}'
set key outside bottom center

plot '#{title}.tsv' with lines t '#{title}'
THE_END

    temp_gnuplot = File.new("temp.gplot", "w")
    temp_gnuplot.puts gnuplot_headder
    temp_gnuplot.close

    result = `gnuplot temp.gplot`
    result = `rm temp.gplot`

end
