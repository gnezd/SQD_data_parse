# Parsing note

## 13 Feb
* 6 in a row. Last byte seems like "x axis"

## 21 Feb: File size analysis

||Desc|Scans|Spectral range|Spectral points|DAT size|IDX size|STS size|
|--|--|--|--|--|--|--|--|
|Function1|TIC+|887|100-500|1:2580, 887:2814|20292480|19514|138239|
|Function2|TIC-|887|100-500|1:23, 2:217, 3, 527, 887: 1207|11139936|19514|138239|
|Function3|DAD|3901|210-600|1: 390, 2, 259, 3901:172, 3900:172|9128340|85822|-|

Size analysis calculations:
[Here](https://docs.google.com/spreadsheets/d/1MsC3vxKqi8805vH02juFBxap4zO-_4S6p9Yg0vwdXMM/edit?usp=sharing)
Comments pending

## 09 Mar Somethings revealed in the past few weeks
* IDX
IDX files contains the index to each acquisition scan in a DAT file. Eacy entry contains 22 bytes:

|Bytes|0-3|4-5|6-11|12-15|16-21|
|--|--|--|--|--|--|
|-|Long int|Short int|?|Single float|?|
|Function|Pointer to the beginning of scan|# of spectral points in this scan|?|Retention time in min|?|

Some regularity and hypotheses in the mysterious bytes 6-11 and 16-21:
** Bytes 6..7 are always 00-18 in MS+ and MS-
** Bytes 8..11 seems to be accumulative signal over all spectral span!


* DAT
