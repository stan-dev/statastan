capture program drop inline
program define inline
syntax , MODELfile(string) THISfile(string)
// what if modelfile already exists? should there be a replace suboption?

tempname fin
local tdir=c(tmpdir)
// fetch temp do-file copy if no thisfile has been named
if "`thisfile'"=="" {
	tempname lsin
	if linux | osx
		shell ls `tdir' -t >>  tdir-ls
	else if windows
		shell dir `tdir' -t >> tdir-ls
	file open lsin using "tdir-ls" // assumes there's nothing else on the 1st line
	file read `lsin' thisfile // is this OK? it will overwrite the thisfile local
	while substr("`thisfile'",1,2)!="SD" { // this SD* is not true for all Stata-OS combinations
		file read `lsin' thisfile
		if eof {
			dis as error "Could not locate a do-file in the Stata temporary folder."
			dis as error "Try giving the path and file name with the 'thisfile' option"
			error 1
		}
	}
}
file open `fin' using "`thisfile'" , read
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
