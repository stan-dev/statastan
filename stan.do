capture program drop stan

program define stan
syntax varlist [if] [in] [, DATAfile(string) MODELfile(string) ///
	INLINE THISFILE(string) ///
	INITsfile(string) LOAD DIAGnose OUTPUTfile(string) MODESFILE(string) ///
	CHAINfile(string) WINLOGfile(string) SEED(integer -1) WARMUP(integer -1) ///
	ITER(integer -1) THIN(integer -1) CMDstandir(string) MODE ///
	SKipmissing MATrices(string) GLobals(string)]

/* options:
	datafile: name to write data into in R/S format (in working dir)
	modelfile: name of Stan model (that you have already saved)
		must end in .stan
		(following John Thompson's lead, if modelfile=="", then look for
		a comment block in your do-file that begins with a line:
		"data {" and this will be written out as the model
	inline: read in the model from a comment block in this do-file
	thisfile: optional, to use with inline; gives the path and name of the
		current active do-file, used to locate the model inline. If 
		thisfile is omitted, Stata will look at the most recent SD* 
		file in c(tmpdir)
	initsfile: name of initial values file in R/S that you have already saved
	load: read iterations into Stata
	diagnose: run gradient diagnostics
	outputfile: name of file to contain Stan output
	modesfile: CSV file to contain posterior modes and BFGS log-probs
		Careful not to mix this up with modelfile!
	chainfile: name of CSV file to contain chain (trimmed version of output.csv)
		to support parallel processing, numbers will be added to this (but not yet)
	winlogfile: in Windows, where to store stdout & stderr before displaying on the screen
	seed: RNG seed
	warmup: number of warmup (burn-in) steps
	iter: number of samples to retain after warmup
	thin: keep every nth sample, for autocorrelation
	cmdstandir: CmdStan path (not including /bin)
	mode: run Stan's optimize funtion to get posterior mode
	skipmissing: omit missing values variablewise to Stan (caution required!!!)
	matrices: list of matrices to write, or 'all'
	globals: list of global macro names to write, or 'all'
	
Notes:
	the executable file and .hpp remains under cdir
	non-existent globals and matrices, and non-numeric globals, get quietly ignored
	missing values are removed casewise by default
	users need to take care not to leave output file names as defaults if they
		have anything called output.csv or modes.csv etc.
*/


local wdir="`c(pwd)'"
local cdir="`cmdstandir'"
/*if "`cdir'"!="" {
	if lower("$S_OS")=="windows" {
		local cdir="`cmdstandir'\"
	}
	else {
		local cdir="`cmdstandir'/"
	}
}*/

// defaults 
if "`datafile'"=="" {
	local datafile="statastan_data.R"
}
if "`modelfile'"=="" {
	local modelfile="statastan_model.stan"
}
/* we assume the modelfile ends ".stan" (CmdStan requires this) because we 
	will chop the last 5 chars off to make the execfile name */
if "`initsfile'"=="" {
	local initlocation=1
}
else {
	if lower("$S_OS")=="windows" {
		local initlocation="`wdir'\`initsfile'"
	}
	else {
		local initlocation="`wdir'/`initsfile'"
	}
}
if "`outputfile'"=="" {
	local outputfile="output.csv"
}
if "`modesfile'"=="" {
	local modesfile="modes.csv"
}
if "`chainfile'"=="" {
	local chainfile="statastan_chains.csv"
}
if "`chainfile'"=="`outputfile'" {
	print as error "chainfile and outputfile cannot have the same name"
	error 1
}
if "`winlogfile'"=="" {
	local winlogfile="winlog.txt" // this only gets used in Windows
}
local lenmod=length("`modelfile'")-5
local execfile=substr("`modelfile'",1,`lenmod')
if lower("$S_OS")=="windows" {
	local execfile="`execfile'"+".exe"
}
// strings to insert into shell command
if `seed'==(-1) {
	local seedcom=""
}
else {
	local seedcom=" random seed=`seed'"
}
if `warmup'==(-1) {
	local warmcom=""
}
else {
	local warmcom=" num_warmup=`warmup'"
}
if `iter'==(-1) {
	local itercom=""
}
else {
	local itercom=" num_samples=`iter'"
}
if `thin'==(-1) {
	local thincom=""
}
else {
	local thincom=" thin=`thin'"
}

preserve
if "`if'"!="" | "`in'"!="" {
	keep `if' `in'
}

// drop missing data casewise
if "`skipmissing'"!="skipmissing" {
	foreach v of local varlist {
		qui count if `v'!=.
		local nthisvar=r(N)
		qui drop if `v'==. & `nthisvar'>1 
	}
}


qui count
local nobs=r(N)

// the capture block ensures the file handles are closed at the end, no matter what
capture noisily {

// inline (John Thompson's approach) model written to .stan file
if "`inline'"!="" {
	tempname fin
	local tdir=c(tmpdir)
	// fetch temp do-file copy if no thisfile has been named
	if "`thisfile'"=="" {
		tempname lsin
		if lower("$S_OS")=="windows" {
			shell dir `tdir' -b -o:-D >> tdir-ls // check this works!
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
			if lower("$S_OS")=="windows" {
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
		dis as error "Model command not found"
		capture file close `fin'
		error 1
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
}


// write data file in R/S format

// first, write out the data in Stata's memory
// this can only cope with scalars (n=1) and vectors; matrices & globals are named in the option
file open dataf using `datafile', write text replace
foreach v of local varlist {
	confirm numeric variable `v'
	local linenum=1
	qui count if `v'!=.
	local nthisvar=r(N)
	if `nthisvar'>1 {
		file write dataf "`v' <- c("
		if "`skipmissing'"=="skipmissing" {
			local nlines=0
			local i=1
			local linedata=`v'[`i']
			while `nlines'<`nthisvar' {
				if `linedata'!=. & `nlines'<(`nthisvar'-1) {
					file write dataf "`linedata', "
					local ++i
					local ++nlines
					local linedata=`v'[`i']
				}
				else if `linedata'!=. & `nlines'==(`nthisvar'-1) {
					file write dataf "`linedata')" _n
					local ++nlines
				}
					
				else {
					local ++i
					local linedata=`v'[`i']
				}
			}
		}
		else {
			forvalues i=1/`nthisvar' {
				local linedata=`v'[`i']
				if `i'<`nthisvar' {
					file write dataf "`linedata', "
				}
				else {
					file write dataf "`linedata')" _n 
				}
			}
		}
	}
	else if `nthisvar'==1 {
		local linedata=`v'[1]
		file write dataf "`v' <- `linedata'" _n
	}
}

// write matrices
if "`matrices'"!="" {
	if "`matrices'"=="all" {
		local matrices: all matrices
	}
	foreach mat in `matrices' {
		capture confirm matrix `mat'
		// -stan- will quietly ignore names of matrices that don't exist
		if !_rc {
			local mrow=rowsof(`mat')
			local mcol=colsof(`mat')
			if `mrow'==1 { // row matrix: write as vector
				if `mcol'==1 { // special case of 1x1 matrix: write as scalar
					local mval=`mat'[1,1]
					file write dataf "`mat' <- `mval'" _n
				}
				else {
					file write dataf "`mat' <- c("
					local mcolminusone=`mcol'-1
					forvalues i=1/`mcolminusone' {
						local mval=`mat'[1,`i']
						file write dataf "`mval',"
					}
					local mval=`mat'[1,`mcol']
					file write dataf "`mval')" _n
				}
			}
			else if `mcol'==1 & `mrow'>1 { // column matrix: write as vector
				file write dataf "`mat' <- c("
				local mrowminusone=`mrow'-1
				forvalues i=1/`mrowminusone' {
					local mval=`mat'[`i',1]
					file write dataf "`mval',"
				}
				local mval=`mat'[`mrow',1]
				file write dataf "`mval')" _n
			}
			else { // otherwise, write as matrix
				file write dataf "`mat' <- structure(c("
				local mrowminusone=`mrow'-1
				local mcolminusone=`mcol'-1
				forvalues j=1/`mcolminusone' {
					forvalues i=1/`mrow' {
						local mval=`mat'[`i',`j']
						file write dataf "`mval',"
					}
				}
				forvalues i=1/`mrowminusone' { // write final column
					local mval=`mat'[`i',`mcol']
					file write dataf "`mval',"
				}
				// write final cell
				local mval=`mat'[`mrow',`mcol']
				file write dataf "`mval'), .Dim=c(`mrow',`mcol'))"
			}
		}
	}
}
// write globals
if "`globals'"!="" {
	if "`globals'"=="all" {
		local globals: all globals
	}
	foreach g in `globals' {
		// -stan- will quietly ignore non-numeric & non-existent globals
		capture confirm number ${`g'}
		if !_rc {
			file write dataf "`g' <- ${`g'}" _n
		}
	}
}
}
file close dataf
restore

// call CmdStan - move to cmdstandir
if lower("$S_OS")=="windows" {
	cd "`cdir'"
	// check if modelfile already exists in cdir
	confirm file "`cdir'\\`modelfile'"
	if !_rc {
		tempfile working
		shell fc /lb2 "`wdir'\\`modelfile'" "`cdir'\\`modelfile'" > "`working'"
// BUT I'M WORRIED THE PATH IN working NEEDS BACKSLASH-ESCAPING
// TEST AND COMPLETE THIS ON A WINDOWS MACHINE
		// if different shell copy "`wdir'\\`modelfile'" "`cdir'\\`modelfile'"
	}
	else {
		shell copy "`wdir'\\`modelfile'" "`cdir'\\`modelfile'"
	}
	dis as result "###############################"
	dis as result "###  Output from compiling  ###"
	dis as result "###############################"
	shell make "`execfile'" > "`winlogfile'"
	type "`winlogfile'"
	// leave modelfile in cdir so make can check need to re-compile
	// shell del "`cdir'\`modelfile'"

	dis as result "##############################"
	dis as result "###  Output from sampling  ###"
	dis as result "##############################"
	shell "`cdir'\\`execfile'" sample`warmcom'`itercom'`thincom'`seedcom' data file="`wdir'\\`datafile'" output file="`wdir'\\`outputfile'" > "`winlogfile'" 2>&1
	type "`winlogfile'"
	shell "bin\print.exe" "`outputfile'" > "`winlogfile'" 2>&1
	type "`winlogfile'"
	// reduce csv file
	file open ofile using "`wdir'\\`outputfile'", read 
	file open rfile using "`wdir'\\`chainfile'", write text replace
	capture noisily {
	file read ofile oline
	while r(eof)==0 {
		//dis as result "`oline'" // for debuggin'
		if length("`oline'")!=0 {
			local firstchar=substr("`oline'",1,1)
			if "`firstchar'"!="#" {
				file write rfile "`oline'" _n
			} 
		}
		file read ofile oline
	}
	}
	file close ofile
	file close rfile
	
	if "`mode'"=="mode" {
		dis as result "#############################################"
		dis as result "###  Output from optimizing to find mode  ###"
		dis as result "#############################################"
		shell "`cdir'\\`execfile'" optimize data file="`wdir'\\`datafile'" output file="`wdir'\\`outputfile'" > "`winlogfile'" 2>&1
		type "`winlogfile'"
		// extract mode and lp__ from output.csv
		file open ofile using "`wdir'\\`outputfile'", read 
		file open mfile using "`wdir'\\`modesfile'", write text replace
		capture noisily {
		file read ofile oline
		while r(eof)==0 {
			if length("`oline'")!=0 {
				local firstchar=substr("`oline'",1,1)
				if "`firstchar'"!="#" {
					file write mfile "`oline'" _n
				} 
			}
			file read ofile oline
		}
		}
		file close ofile
		file close mfile
		preserve
			insheet using "`wdir'\\`modesfile'", comma names clear
			local lp=lp__[1]
			dis as result "Log-probability at maximum: `lp'"
			drop lp__
			xpose, clear varname
			qui count
			local npars=r(N)
			forvalues i=1/`npars' {
				local parname=_varname[`i']
				label define parlab `i' "`parname'", add
			}
			encode _varname, gen(Parameter) label(parlab)
			gen str14 Posterior="Mode"
			tabdisp Parameter Posterior, cell(v1) cellwidth(9) left
		restore
	}
	
	if "`diagnose'"=="diagnose" {
		dis as result "#################################"
		dis as result "###  Output from diagnostics  ###"
		dis as result "#################################"
		shell "`cdir'\\`execfile'" diagnose data file="`wdir'\\`datafile'" > "`winlogfile'" 2>&1
		type "`winlogfile'"
	}
	cd "`wdir'"
}
else {
	cd "`cdir'"
	// check if modelfile already exists in cdir
	confirm file "`cdir'/`modelfile'"
	if !_rc {
		tempfile working
		shell diff -b "`wdir'/`modelfile'" "`cdir'/`modelfile'" > "`working'"
		tempname wrk
		file open `wrk' using "`working'", read text
		file read `wrk' line
		if "`line'" !="" {
			shell copy "`wdir'/`modelfile'" "`cdir'/`modelfile'"
		}
	}
	else {
		shell copy "`wdir'/`modelfile'" "`cdir'/`modelfile'"
	}

	shell cp "`wdir'/`modelfile'" "`cdir'/`modelfile'"
	dis as result "###############################"
	dis as result "###  Output from compiling  ###"
	dis as result "###############################"
	shell make "`execfile'"
	// leave modelfile in cdir so make can check need to re-compile
	// shell rm "`cdir'/`modelfile'"

	dis as result "##############################"
	dis as result "###  Output from sampling  ###"
	dis as result "##############################"
	shell "`cdir'/`execfile'" sample`warmcom'`itercom'`thincom'`seedcom' init="`initlocation'" data file="`wdir'/`datafile'" output file="`wdir'/`outputfile'"
	shell bin/print "`wdir'/`outputfile'"
	
	// reduce csv file
	file open ofile using "`wdir'/`outputfile'", read 
	file open rfile using "`wdir'/`chainfile'", write text replace
	capture noisily {
	file read ofile oline
	while r(eof)==0 {
		if length("`oline'")!=0 {
			local firstchar=substr("`oline'",1,1)
			if "`firstchar'"!="#" {
				file write rfile "`oline'" _n
			} 
		}
		file read ofile oline
	}
	}
	file close ofile
	file close rfile

	if "`mode'"=="mode" {
		dis as result "#############################################"
		dis as result "###  Output from optimizing to find mode  ###"
		dis as result "#############################################"
		shell "`cdir'/`execfile'" optimize data file="`wdir'/`datafile'" output file="`wdir'/`outputfile'"
		// extract mode and lp__ from output.csv
		file open ofile using "`wdir'/`outputfile'", read 
		file open mfile using "`wdir'/`modesfile'", write text replace
		capture noisily {
		file read ofile oline
		while r(eof)==0 {
			if length("`oline'")!=0 {
				local firstchar=substr("`oline'",1,1)
				if "`firstchar'"!="#" {
					file write mfile "`oline'" _n
				} 
			}
			file read ofile oline
		}
		}
		file close ofile
		file close mfile
		preserve
			insheet using "`wdir'/`modesfile'", comma names clear
			local lp=lp__[1]
			dis as result "Log-probability at maximum: `lp'"
			drop lp__
			xpose, clear varname
			qui count
			local npars=r(N)
			forvalues i=1/`npars' {
				local parname=_varname[`i']
				label define parlab `i' "`parname'", add
			}
			encode _varname, gen(Parameter) label(parlab)
			gen str14 Posterior="Mode"
			tabdisp Parameter Posterior, cell(v1) cellwidth(9) left
		restore
	}
	if "`diagnose'"=="diagnose" {
		dis as result "#################################"
		dis as result "###  Output from diagnostics  ###"
		dis as result "#################################"
		shell "`cdir'/`execfile'" diagnose data file="`wdir'/`datafile'"
	}
	cd "`wdir'"
}

if "`load'"=="load" {
	dis as result "############################################"
	dis as result "###  Now loading Stan output into Stata  ###"
	dis as result "############################################"
	// read in output and tabulate
	insheet using "`chainfile'", comma names clear
	qui ds
	local allvars=r(varlist)
	gettoken v1 vn: allvars, parse(" ")
	while "`v1'"!="n_divergent__" {
		gettoken v1 vn: vn, parse(" ")
	}
	tabstat `vn', stat(n mean sd semean min p1 p5 p25 p50 p75 p95 p99)
	foreach v of local vn {
		qui centile `v', c(2.5 97.5)
		local cent025_`v'=r(c_1)
		local cent975_`v'=r(c_2)
		dis as result "95% CI for `v': `cent025_`v'' to `cent975_`v''"
	}
}

end
