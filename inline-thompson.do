capture program drop inline
program define inline
syntax , MODELfile(string) [THISfile(string)]
// what if modelfile already exists? should there be a replace suboption?

tempname fin
local tdir=c(tmpdir)
// fetch temp do-file copy if no thisfile has been named
if "`thisfile'"=="" {
	tempname lsin
	if "$S_OS"=="windows" {
		shell dir `tdir' -b -o:-D >> tdir-ls 
	}
	else {
		shell ls `tdir' -t >>  tdir-ls
	}
	tempname lsin
	capture file close `lsin'
	file open `lsin' using "tdir-ls", read text 
	// assumes there's nothing else on the 1st line
	file read `lsin' thisfile // is this OK? it will overwrite the thisfile local
	while substr("`thisname'",1,2)!="SD" { // this SD* is not true for all Stata-OS combinations
		file read `lsin' thisname
		if "$S_OS"=="windows" {
			local thisfile "`tdir'\`thisname'"
		}
		else {
			local thisfile "`tdir'/`thisname'"
		}
		if r(eof)==1 {
			dis as error "Could not locate a do-file in the Stata temporary folder."
			dis as error "Try giving the path and file name with the 'thisfile' option"
			capture file close `lsin'
			error 1
		}
	}
	capture file close `lsin'
}
tempname fin
capture file close `fin'
file open `fin' using "`thisfile'" , read text
file read `fin' line

tokenize `"`line'"'
local line1=`"`1'"'
file read `fin' line
tokenize `"`line'"'
while (("`line1'"!="/*" | substr(`"`1'"',1,4)!="data") & !r(eof)) {
	local line1="`1'"
	file read `fin' line
	tokenize `"`line'"'
}
if r(eof) {
	di "Model command not found"
	file close `fin'
	exit(0)
}

tempname fout
capture file close `fout'
file open `fout' using "`modelfile'" , write replace
file write `fout' "`line'" _n
file read `fin' line
while ("`line'"!="*/") {
	file write `fout' "`line'" _n
	file read `fin' line
}
file close `fin'
file close `fout'
end
