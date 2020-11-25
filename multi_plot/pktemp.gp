set terminal svg mouse enhanced jsdir './js/' size 1000 600
set output 'blah.svg'
set datafile separator ','
set xlabel 'rt'
set xtics nomirror out scale 0.5, 0.25
set mxtics 10
set ytics nomirror scale 0.5
set y2tics
set y2range [-1.1:1.1]
plot 'table.csv' using 1:2 with lines t 'orig', '' using 3:4 with lines t 'ma3', '' using 5:6 with lines t 'deriv\_10.48\_n' axis x1y2, '' using 7:8 with lines t 'deriv2\_n' axis x1y2, 'peaks.csv' using 1:2:('x') t 'peaks' with labels axis x1y2
