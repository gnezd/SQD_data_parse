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
		puts "Reading #{idxs[func_num]}"
	end
end

puts "Input command (q to quit. F to start parsing functions.):"
command = STDIN.gets#command mode loop
end #while command input loop

=begin

fin = File.open(fname+'.IDX', "rb")
#fo = File.open(ARGV[3], "w")
puts "Opening function #{fname}, and idx file size is #{fin.size}"


scan_num=ARGV[1].to_i

idx = fin.read
fin.close
ctr=0


accumulates = Hash.new(0)

scan_begin = []
scan_size = []
rt =[]

while ctr < idx.size-1
	unpacked = unpack_idx(idx[ctr..ctr+22])
	accumulates["points_from_IDX"] += unpacked[1].to_i
	scan_begin.push unpacked[0]
	scan_size.push unpacked[1]
	rt.push unpacked[2]
	ctr += 22
end


puts accumulates
puts scan_begin.size

fin = File.open(fname+".DAT", "rb")
dat = fin.read


puts "Scan #{scan_num} begins at #{scan_begin[scan_num]} and spans #{scan_size[scan_num]} * 6 bytes"
scan_ext = dat[scan_begin[scan_num]..(scan_begin[scan_num]+scan_size[scan_num])*6-1]
(0..(scan_ext.size)/6-1).each do |i|
	pt_str = scan_ext[6*i..6*i+5]
	#puts "#{i}:\t|" + display_bytes(pt_str,'|') + "|\t" + pt_str[4..5].unpack('L')[0].to_s
	puts display_bytes(pt_str,' ') + "\t#{pt_str[0..1].unpack('S')[0]}\t#{pt_str[2].unpack('C')[0]}\t#{("\0"+pt_str[3..5]).unpack('L')[0]/256}"
end
=end
