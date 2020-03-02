#!/usr/bin/ruby

require './lib.rb'



fname=ARGV[0]

raise "No file name given" unless fname
puts "Checking integrity of raw file..."
script_root = Dir.pwd
raise "File doesn't exist" unless Dir.chdir fname

func_dats = Dir.glob("#{Dir.pwd}/_FUNC*.DAT").sort!
chrom_dats = Dir.glob("#{Dir.pwd}/_CHRO*.DAT")
raise "No DAT files found!" if func_dats.empty?

puts "Directory found. Checking if _FUNC*.DATs have .IDXs"
idxs = Dir.glob("#{Dir.pwd}/*.IDX").sort!
puts "Warning: Number of .IDX files (#{idxs.size}) doesn't match with that of function .DAT files (#{func_dats.size})!" unless idxs.size == func_dats.size
func_dats.each {|funcdat| raise "#{funcdat} has no corresponding .IDX!" unless idxs.one? {|idx| funcdat[0..-4] == idx[0..-4]} }

puts "All set. #{chrom_dats.size} chromatograms and #{func_dats.size} functions found."

puts "Input command (q to quit. F to start parsing functions.):"
command = STDIN.gets#command mode loop


while true 

if command == "q\n"
	puts "Exit"
	exit
end

while command == "F\n"
	puts "Function reading mode. Which function would you like to read?"
	func_dats.each_index {|n| puts "#{n}) #{File.basename(func_dats[n])}"}
	puts "Enter number (q to exit):"
	func_num = STDIN.gets
	if func_num.chomp == "q"
 		puts "Back to main menu."
		command = 0
	elsif func_dats[func_num.to_i]
		func_num=func_num.to_i
		fin = File.open(idxs[func_num], "rb")
		idx = fin.read
		fin.close
		puts "Read in #{idxs[func_num]}, and file size #{idx.size} = #{idx.size/22} scan lines. Which line would you extract?"
		scan_num = STDIN.gets.to_i
		puts "Output to file? (empty for stdin)"
		outpath = STDIN.gets.chomp
		if outpath == ""
			fo = STDOUT
		else
			fo = File.open(script_root+'/'+outpath, "w")
		end 
		
		accumulates = Hash.new(0) #parameters that accumulate acros an idx file
		scan_begin = []
		scan_size = []
		idx_mystery1 = []
		idx_mystery2 = []
		rt =[]

		ctr = 0
		while ctr < idx.size-1
			unpacked = unpack_idx(idx[ctr..ctr+21])
			accumulates["points_from_IDX"] += unpacked[1].to_i #num of 6 byte data points
			scan_begin.push unpacked[0]
			scan_size.push unpacked[1]
			rt.push unpacked[2]
			idx_mystery1.push idx[ctr+6..ctr+11]
			idx_mystery2.push idx[ctr+16..ctr+21]
			ctr += 22
		end
		
		fin = File.open(func_dats[func_num], "rb")
		dat = fin.read
		fin.close
		raise "6B data point number from .DAT (#{dat.size/6}) doesn't match that designated in IDX(#{accumulates["points_from_IDX"]}!)"	if dat.size/6 != accumulates["points_from_IDX"]
		
		puts "Scan #{scan_num} begins at #{scan_begin[scan_num]} and spans #{scan_size[scan_num]} * 6 bytes"
		#scan_ext = dat[scan_begin[scan_num]..(scan_begin[scan_num]+scan_size[scan_num])*6-1]
		
		fo.puts "<Function #{func_num}, scan ##{scan_num}, time #{rt[scan_num]}>"
		fo.puts display_bytes(idx_mystery1[scan_num], '-') + "\t" + display_bytes(idx_mystery2[scan_num], '-')
		fo.puts "raw_mcr\traw_count\tmcr_multiplier\tcount_gain"
		(0..scan_size[scan_num]-1).each do |i| #each spectral point
			pt6b = dat[scan_begin[scan_num]+6*i..scan_begin[scan_num]+6*i+5] #this 6 byte data point
			#raw_count = pt6b[0..1].unpack('S')[0] #ion count
			raw_count = pt6b[0..1].unpack('s')[0] #ion count, signed?
			count_gain = 4**(pt6b[2].unpack('C')[0] % 16)
			mcr_multiplier = 2**((pt6b[2].unpack('C')[0]/16).floor-7)
			raw_mcr = ("\0"+pt6b[3..5]).unpack('L')[0]/256 #mcr = mass-charge ratio
			fo.puts "#{raw_mcr}\t#{raw_count}\t#{mcr_multiplier}\t#{count_gain}"
		end #each spectral point
		if fo != STDOUT
			puts "Written function #{func_num}, scan ##{scan_num} to file: #{fo.path}" 
			fo.close
		end
	end #while command == "F"
end

puts "Input command (q to quit. F to start parsing functions.):"
command = STDIN.gets#command mode loop
end #while command input loop

=begin


=end
