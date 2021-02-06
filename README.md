# Waters LCMS SQD raw file format reverse engineering

## Requirements
1. Ruby
2. Gnuplot

## Usage
### For Rubyists
```
require 'lib.rb' 
```
### For plotting users
1. Edit `list.csv` in `multi_plot` to indicate path to the raw datafile and m/z / wavelength / retention pickings.
2. Open terminal
```
cd multi_plot
ruby multiple_plot.rb
```
3. Find your plots in svg format in Plot-(date-HHMMSS) folder, chromatogram/spectrum data in csv format.
A demo [Video](https://www.dropbox.com/s/a9oswtrcq8p0da4/SQD_data_demo.mov?dl=0) might help to explain how it works.
