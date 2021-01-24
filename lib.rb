#!/usr/bin/ruby
# Main library for Waters SQD data parsing
# Requirement: gnuplot
# Content: Class definition of Masslynx_Function
# And some orphan functions: display_bytes(), bin_x(), chromatogram_extract(), spectrum() and plot()
require 'CSV'

class MasslynxFunction
  attr_reader :fname, :func_num, :size, :spect, :counts, :scan_index, :scan_size, :total_trace, :retention_time

  def initialize(fname, func_num)
    @fname = fname
    @func_num = func_num

    idx_in = File.open(fname + "/_FUNC00#{@func_num}.IDX", "rb")
    idx_raw = idx_in.read.freeze
    idx_in.close
    raise "#{fname}/_FUNC00#{@func_num}.IDX corrupt" if idx_raw.size % 22 != 0

    @size = idx_raw.size / 22 # number of scan time points

    @spect = Array.new(@size) { Array.new() { 0.0 } }
    @counts = Array.new(@size) { Array.new(0) { 0 } }
    @scan_index = Array.new(@size) { 0 } # Position of beginning of time scan in .DAT
    @scan_size = Array.new(@size) { 0 } # Length of scan data
    @total_trace = Array.new(@size) { 0.0 } # Total count trace
    @retention_time = Array.new(@size) { 0.0 } # Retention time of each scan

    scan_num = 0
    while scan_num < @size
      # info from IDX
      scan_begin, scan_size_r, accumulate, rt = idx_raw[22 * scan_num, 22].unpack("L S x x f f")
      @scan_index[scan_num] = scan_begin
      @scan_size[scan_num] = scan_size_r
      @total_trace[scan_num] = accumulate
      @retention_time[scan_num] = rt
      scan_num += 1
    end
  end

  def raw_loaded?
    return false if (@spect == Array.new(@size) { Array.new() { 0.0 } }) & (@counts == Array.new(@size) { Array.new(0) { 0 } })

    return true
  end

  def load_raw
    # Extract data from .DAT
    raw_in = File.open(@fname + "/_FUNC00#{@func_num}.DAT", "rb")
    dat_raw = raw_in.read.freeze
    raw_in.close

    scan_num = 0 # iterate timepoint scan
    while scan_num < @size
      # puts "scan_num: #{scan_num}, index: #{@scan_index[scan_num]}"
      (0..@scan_size[scan_num] - 1).each do |spect| # iterate spectral value
        raw_count, byte3, raw_mcr, raw_mcr256 = dat_raw[@scan_index[scan_num] + spect * 6, 6].unpack("s C C S")
        # Real magic of data conversion. See note.
        @spect[scan_num][spect] = ((2**((byte3 / 16).floor - 7)) * (raw_mcr256 * 256 + raw_mcr) - 46384).to_f / 131034
        @counts[scan_num][spect] = raw_count * (4**(byte3 % 16)).to_int
      end
      scan_num += 1
    end
  end

  def inspect
    return { 'fname' => @fname, 'func_num' => @func_num, 'size' => @size, 'raw_loaded?' => raw_loaded? }
  end

  def extract_chrom(x_0, x_1)
    # Extract chromatogram in given spectral range. Returns <Chromatogram>chrom, <int>Spectral width
    # Raw data comes in 1M * abs, devide away in the end
    load_raw unless raw_loaded?
    # construct chromatogram name
    #puts @func_num
    case @func_num
    when 1
      name = "ESI+ XIC #{x_0}~#{x_1} Da"
      units = ["mins", "counts"]
    when 2
      name = "ESI- XIC #{x_0}~#{x_1} Da"
      units = ["mins", "counts"]
    when 3
      name = "UV band chromatogramms #{x_0}~#{x_1} nm"
      units = ["mins", "abs * spectral_width"]
    end
    # construct units
    puts "units feeding: #{units}" # debug
    chrom = Chromatogram.new(@size, name, units)
    spectral_width = 0 # for normalizing UV abs

    (0..@size - 1).each do |scan| # each scan
      chrom[scan][0] = @retention_time[scan]
      spectral_width_t = 0 # Spectral width at this scan: varies because of zero-cutoff
      (0..@spect[scan].size - 1).each do |spect| # each spectral point
        #The real spectrum cut happens here
        next if @spect[scan][spect] < x_0
        break if @spect[scan][spect] > x_1

        spectral_width_t += 1
        chrom[scan][1] += @counts[scan][spect]
      end
      chrom[scan][1] = chrom[scan][1].to_f / 1000000 if @func_num == 3
      # Devide away 1M if this is UV trace
      spectral_width = (spectral_width_t > spectral_width) ? spectral_width_t : spectral_width
    end

    chrom.desc['spectral_width'] = spectral_width
    return chrom
  end

  def extract_spect(t_0, t_1) # Extract spectrum in given retention time range
    # DANGER of NOT binning!!!!! (10 Nov 2020)
    # Decides not to bin, but normalize towards chrom_width
    load_raw unless raw_loaded?
    sum = Hash.new { 0 }
    chrom_width = 0 # for UV normalization
    (0..@size - 1).each do |scan|
      next if @retention_time[scan] < t_0
      break if @retention_time[scan] > t_1
      #puts "extracting #{scan}" #debug
      chrom_width += 1
      (0..@spect[scan].size - 1).each do |sp|
        sum[@spect[scan][sp]] += @counts[scan][sp]
      end
    end
    normalizer = (@func_num == 3) ? (chrom_width * 10**6) : 1
    puts "Spectral normalizer is #{normalizer}"
    result = sum.sort.to_a.map {|pt| [pt[0], pt[1].to_f / normalizer]}
    result
  end

end

class Chromatogram

  attr_accessor :name, :units, :rt_range, :signal_range, :desc, :size
  def initialize(size, name, units, desc = nil)
    raise "units format should be an arr of two strings, but is fed #{units}" unless units.is_a?(Array) && units.size == 2 && units.all? { |elements| elements.is_a?(String)}
    rasie "Size doesn't make sense" unless size.is_a?(Integer) && size >= 0

    @size = size
    @data = Array.new(size) { [0.0, 0] }
    @name = name.to_s
    @units = units
    @desc = desc ? desc : Hash.new
  end

  def inspect
    return { 'name' => @name, 'size' => @size, 'rt_range' => @rt_range, 'signal_range' => @signal_range, 'desc' => @desc }
  end

  def update_info
    @rt_range = @data.minmax_by { |pt| pt[0] }.map{ |pt| pt[0] }
    @signal_range = @data.minmax_by { |pt| pt[1] }.map{ |pt| pt[1] }
  end

  def [](i)
    # This is problematic. Should inherit better the behavior of an array
    @data[i]
  end

  def push(pt)
    raise if pt.class != Array || pt.size != 2

    @data.push pt
  end

  def []=(i, input)
    @data[i] = input
  end

  def to_a
    @data[0..@size-1]
  end

  def transpose
    rt = (0..@size-1).map {|x| @data[x][0]}
    y = (0..@size-1).map {|x| @data[x][1]}
    [rt, y]
  end

  def normalize
    # normalize to max
    update_info
    #puts [@units[0], "Normalized #{@units[1]}"]#, "#{@name}-int:#{@signal_range[1]}")
    result = Chromatogram.new(@data.size, "#{@name}-normalized", [@units[0], "Normalized #{@units[1]}"], "#{@name}-int:#{@signal_range[1]}")
    @data.each_index do |i|
      result[i] = [@data[i][0], @data[i][1].to_f / @signal_range[1]]
    end
    result
  end

  def deriv
    # Simple derivative
    result = Chromatogram.new(@data.size-1, "#{@name}-derivative", [@units[0], "d(#{@units[1]})/dt"])
    (0..result.size-1).each do |i|
      result[i] = [(@data[i][0] + @data[i+1][0]).to_f / 2, (@data[i+1][1]-@data[i][1]).to_f / (@data[i+1][0]-@data[i][0])]
    end
    result
  end

  def ma(radius)
    # +- radius points moving average
    # Issue: Radius defined on no of points but not real time units
    raise "Radius should be integer but was given #{radius}" unless radius.is_a?(Integer)
    raise "Radius larger than half the length of chromatogram" if 2*radius >= @size

    result = Chromatogram.new(@data.size-2*radius, "#{@name}-#{radius}ma", @units)
    result.each_index do |i|
      # Note that the index i of the moving average chromatogram aligns with i + radius in originaal chromatogram
      x = @data[i + radius][0]
      y = 0.0
      (i .. i + 2 * radius).each do |origin_i|
        # Second loop to run through the neighborhood in origin
        # Would multiplication with a diagonal stripe matrix be faster than nested loop? No idea just yet.
        y += @data[origin_i][1]
      end
      y = y / (2 * radius + 1) # Normalization
      result[i] = [x, y]
    end
    result
  end

  def sd_rank(range, rank)
    update_info
    # Find the SD of less deviating (rank, 0~1) points in range
    raise "Retention time selection #{range} out of chromatogram range #{@rt_range}!" if range[0] < @rt_range[0] || range[1] > @rt_range[1]

    raise "Rank is supposed to be a number between 0 ~ 1 but #{rank} was given" unless 0 <= rank && rank <= 1

    # First cut out sub chromatogram
    index_begin = @data.find_index { |pt| pt[0] >= range[0] }
    index_end = @data.find_index { |pt| pt[0] > range[1] } - 1 #Bug: Will be doing nil - 1 if index_end hits bottom of array
    cut = @data[index_begin..index_end] # Note that this returns an array for now, not Chromatogram
    # Then find average
    avg = cut.map{|pt| pt[1]}.reduce(:+).to_f / cut.size
    # Construct deviation array, sort, pick points, calculate sd
    dev = cut.map{|pt| [pt[0], avg - pt[1]]}
    dev.sort! {|pta, ptb| pta[1]**2 <=> ptb[1]**2}
    cut = dev[0..(dev.size*rank).to_i] # cut out the top ranking close to avg. Not the reuse of cut and avg
    puts cut
    avg = cut.map{|pt| pt[1]}.reduce(:+).to_f / cut.size
    (cut.map{ |pt| (pt[1] - avg)**2 }.reduce(:+).to_f / cut.size)**0.5
  end

  def write_to(target) # write to 2d array or file
    # if file exist, append
    # if not, create
    # if 2d array, transpose and append
    # consult peaks.rb datatable
  end
end

# WHERE DO I PUT THE datatable(chroms, titles) ??
# It's own class? or??

# pack up the plotting

class Peak
  attr_accessor :begin, :end, :height, :area, :name, :note

  def initialize(beg, endd)
    self.begin = beg
    self.end = endd
  end
end

def display_bytes(str, delim) # Bytewise show string in hex with deliminator
  ret = Array.new
  str.each_byte do |byte|
    ret.push ("%02X" % byte)
  end
  return ret.join(delim)
end

def bin_x(range, ms_func) # Bin the spectral domain of a Masslynx_Function io designated range and resolution
  range_begin, range_end, increment = range
  width = ((range_end - range_begin) / increment).ceil
  binned = Array.new(ms_func.spect.size) { Array.new(width) { 0 } }
  spect_value = [''] + (0..width).map { |x| range_begin + x * increment }
  (1..ms_func.size - 1).each do |i|
    ms_func.spect[i].each_index do |spect|
      x = ((ms_func.spect[i][spect] - range_begin) / increment).ceil
      break if x > width - 1
      next if x <= 0

      binned[i][x] += ms_func.counts[i][spect]
    end
  end

  return binned, spect_value
end

def plot(data, title, outpath) # Plot xy function with title with gnuplot
  fo = File.open("#{title}.tsv", "w") # generate tsv
  data.each do |pt|
    fo.puts pt[0].to_s + "\t" + pt[1].to_s
  end
  fo.close

  gnuplot_headder = <<~THE_END
          set terminal svg enhanced mouse
          set output '#{outpath}'
          set key outside bottom center
    #{'      '}
          plot '#{title}.tsv' with lines t '#{title}'
  THE_END

  temp_gnuplot = File.new("temp.gplot", "w")
  temp_gnuplot.puts gnuplot_headder
  temp_gnuplot.close
  gnuplot_exe = which 'gnuplot'
  if gnuplot_exe
    result = `#{gnuplot_exe} temp.gplot`
    result = `rm temp.gplot`
  else
    puts 'Gunplot not found. Please plot temp.gplot manually.'
  end
end

def multi_plot(chroms, titles, outdir, svg_name)
  # chroms and titles should be arrays
  # or define a data class chrom? Would actually be reusable?

  # create data table
  table = Array.new
  raise "mismatch length of chromatograms and titles!" if chroms.size != titles.size

  max_chrom_length = (chroms.max_by { |chrom| chrom[0].size })[0].size
  #puts "chrom lengths: #{chroms.map {|chr| chr[0].size}}"
  #puts "max chrom length: #{max_chrom_length}"
  chroms.each_index do |i|
    table.push([titles[i]] + chroms[i][0] + ([''] * (max_chrom_length - chroms[i][0].size))) # Title - x values - blank filling to the max chrom length in this plot
    table.push([''] + chroms[i][1] + ([''] * (max_chrom_length - chroms[i][0].size))) # blank - y values - blank filling
  end
  table = table.transpose

  # create data csv for post-process
  csv_name = "#{outdir}/#{svg_name}.csv"
  fo = File.new(csv_name, "w")
  csv_out = CSV.new(fo)
  table.each do |row|
    csv_out << row
  end
  fo.close

  gnuplot_headder = <<~THE_END
    set datafile separator ','
    set terminal svg enhanced mouse standalone
  THE_END

  annotations = <<~THE_END
    set xlabel 'Retention time (min)' offset 0, 0.5
    set xtics nomirror out scale 0.5, 0.25
    set mxtics 10
    set yrange [*:*]
    set ytics nomirror scale 0.5
    set ylabel 'Normalized ion counts' offset 2.5,0
    set y2tics scale 0.5
    set y2label 'Absorption (10^{-6} a.u.)' offset -  2.5,0
    set terminal svg enhanced mouse standalone size 1200 600 font "Calibri, 16"
    set margins 5,9,2.5,0.5
    set linetype 1 lc rgb "black" lw 2
    set linetype 2 lc rgb "dark-red" lw 2
    set linetype 3 lc rgb "olive" lw 2
    set linetype 4 lc rgb "navy" lw 2
    set linetype 5 lc rgb "red" lw 2
    set linetype 6 lc rgb "dark-turquoise" lw 2
    set linetype 7 lc rgb "dark-blue" lw 2
    set linetype 8 lc rgb "dark-violet" lw 2
    set linetype cycle 8
    set output '#{outdir}/#{svg_name}.svg'
  THE_END

  # plot_line compilation
  plot_line = "plot '#{csv_name}'"
  raise if (table[0].size % 2) != 0

  i = 0
  while i < table[0].size
    plot_line += ", ''" if i > 0
    plot_line += " using #{i + 1}:($#{i + 2}) with lines t '#{titles[i / 2]}'"
    plot_line += " axis x1y2" if titles[i / 2] =~ /nm$/
    i += 2
  end

  temp_gnuplot = File.new("temp.gplot", "w")
  temp_gnuplot.puts gnuplot_headder
  temp_gnuplot.puts annotations
  temp_gnuplot.puts plot_line
  temp_gnuplot.close
  gnuplot_exe = which 'gnuplot'
  if gnuplot_exe
    result = `gnuplot temp.gplot`
  else
    puts 'Gnuplot not found. Please plot temp.gplot manually'
  end
end

# Cross-platform way of finding an executable in the $PATH.
# Copied from https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
# which('ruby') #=> /usr/bin/ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end