capture program drop stan

program define stan
version 11.0
syntax varlist [if] [in] [, DATAfile(string) MODELfile(string) ///
	INLINE THISFILE(string) RERUN ///
	INITsfile(string) LOAD DIAGnose OUTPUTfile(string) MODESFILE(string) ///
	CHAINFile(string) WINLOGfile(string) SEED(integer -1) CHAINS(integer 1) ///
	WARMUP(integer -1) ITER(integer -1) THIN(integer -1) CMDstandir(string) ///
	MODE SKipmissing MATrices(string) GLobals(string) KEEPFiles ///
	STEPSIZE(real 1) STEPSIZEJITTER(real 0)]

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
	rerun: if specified, uses the existing executable file with the same name as
		modelfile (in Windows, it will have .exe extension). This should exist in the
		cmdstandir (see below). Be aware it will be copied into the working directory,
		overwriting any existing file of that name.
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
	chains: number of chains
	warmup: number of warmup (burn-in) steps
	iter: number of samples to retain after warmup
	thin: keep every nth sample, for autocorrelation
	cmdstandir: CmdStan path (not including /bin)
	mode: run Stan's optimize funtion to get posterior mode
	skipmissing: omit missing values variablewise to Stan (caution required!!!)
	matrices: list of matrices to write, or 'all'
	globals: list of global macro names to write, or 'all'
	keepfiles: if stated, all files generated are kept in the working directory; if not,
		all are deleted except the modelfile, C++ code, the executable, the modesfile and
		the chainfile.
	stepsize: HMC stepsize, gets passed to CmdStan
	stepsize_jitter: HMC stepsize jitter, gets passed to CmdStan

Notes:
	non-existent globals and matrices, and non-numeric globals, get quietly ignored
	missing values are removed casewise by default
	users need to take care not to leave output file names as defaults if they
		have anything called output.csv or modes.csv etc. - these will be overwritten!
*/

local statastanversion="1.2.3"
local wdir="`c(pwd)'"
local cdir="`cmdstandir'"

// get CmdStan version
tempname cmdstanversioncheck // note this is tempname not tempfile
if lower("$S_OS")=="windows" {
	shell "`cdir'\bin\stanc" --version >> "`cmdstanversioncheck'"
}
else {
	shell "`cdir'/bin/stanc" --version >> "`cmdstanversioncheck'"
}
file open cv using "`cmdstanversioncheck'", read
file read cv cvline
local cmdstanversion=substr("`cvline'",15,.)
dis as result "StataStan version: `statastanversion'"
dis as result "CmdStan version: `cmdstanversion'"
file close cv
if lower("$S_OS")=="windows" {
	shell del "`cmdstanversioncheck'"
}
else {
	shell rm "`cmdstanversioncheck'"
}

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
		local initlocation="`wdir'\\`initsfile'"
	}
	else {
		local initlocation="`wdir'/`initsfile'"
	}
}
// this holds the entered name but .csv will be appended later
if "`outputfile'"=="" {
	local outputfile="output"
}
if "`modesfile'"=="" {
	local modesfile="modes.csv"
}
if "`chainfile'"=="" {
	local chainfile="statastan_chains.csv"
}
if "`chainfile'"=="`outputfile'" | "`chainfile'"=="`outputfile'.csv" {
	print as error "chainfile and outputfile cannot have the same name"
	error 1
}
if "`winlogfile'"=="" {
	local winlogfile="winlog.txt" // this only gets used in Windows
}
local lenmod=length("`modelfile'")-5
local execfile=substr("`modelfile'",1,`lenmod')
local deleteme="`execfile'"
if lower("$S_OS")=="windows" {
	local execfile="`deleteme'"+".exe"
}
	local cppfile="`deleteme'"+".hpp"

// strings to insert into shell command
if `seed'==(-1) {
	local seedcom=""
}
else {
	local seedcom="random seed=`seed'"
}
if `chains'<1 {
	dis as error "You must specify 1 or more chains"
	error 1
}
if `warmup'==(-1) {
	local warmcom=""
}
else {
	local warmcom="num_warmup=`warmup'"
}
if `iter'==(-1) {
	local itercom=""
}
else {
	local itercom="num_samples=`iter'"
}
if `thin'==(-1) {
	local thincom=""
}
else {
	local thincom="thin=`thin'"
}
local stepcom="stepsize=`stepsize'"
local stepjcom="stepsize_jitter=`stepsizejitter'"

// check for existing files
tempfile outputcheck
if lower("$S_OS")=="windows" {
	shell if exist "`cdir'\\`outputfile'*.csv" (echo yes) else (echo no) >> "`outputcheck'"
}
else {
	shell test -e "`cdir'/`outputfile'*.csv" && echo "yes" || echo "no" >> "`outputcheck'"
}
file open oc using "`outputcheck'", read
file read oc ocline
if "`ocline'"=="yes" {
	dis as error "There are already one or more files in `cdir' called `outputfile'*.csv"
	dis as error "These may be overwritten by StataStan or incorrectly included in posterior summaries."
	dis as error "Please rename or move them to avoid data loss or errors."
	file close oc
	error 1
}
file close oc
if lower("$S_OS")=="windows" {
	shell if exist "`wdir'\\`outputfile'*.csv" (echo yes) else (echo no) >> "`outputcheck'"
}
else {
	shell test -e "`wdir'/`outputfile'*.csv" && echo "yes" || echo "no" >> "`outputcheck'"
}
file open oc using "`outputcheck'", read
file read oc ocline
if "`ocline'"=="yes" {
	dis as error "There are already one or more files in `wdir' called `outputfile'*.csv"
	dis as error "These may be overwritten by StataStan or incorrectly included in posterior summaries."
	dis as error "Please rename or move them to avoid data loss or errors."
	error 1
}
file close oc

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


// the capture block ensures the file handles are closed at the end, no matter what
capture noisily {

// inline (John Thompson's approach) model written to .stan file
if "`inline'"!="" {
	tempname fin
	tempfile tdirls
	local tdir=c(tmpdir)
	// fetch temp do-file copy if no thisfile has been named
	if "`thisfile'"=="" {
		tempname lsin
		if lower("$S_OS")=="windows" {
			shell dir `tdir' -b -o:-D >> `tdirls'
		}
		else {
			shell ls `tdir' -t >>  `tdirls'
		}
		tempname lsin
		capture file close `lsin'
		file open `lsin' using `tdirls', read text
		// assumes there's nothing else on the 1st line
		file read `lsin' thisfile // is this OK? it will overwrite the thisfile local
		if lower("$S_OS")=="windows" {
			local tempprefix="STD"
		}
		else {
			local tempprefix="SD"
		}
		while substr("`thisname'",1,2)!="`tempprefix'" {
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


/*#############################################################
######################## Windows code #########################
#############################################################*/
if lower("$S_OS")=="windows" {
	// unless re-running an existing compiled executable, move model to cmdstandir
	if "`rerun'"!="rerun" {
		// check if modelfile already exists in cdir
		capture confirm file "`cdir'\\`modelfile'"
		if !_rc {
			// check they are different before copying and compiling
			tempfile working
			shell fc /lb2 "`wdir'\\`modelfile'" "`cdir'\\`modelfile'" > "`working'"
			// if different shell copy "`wdir'\\`modelfile'" "`cdir'\\`modelfile'"
		}
		else {
			windowsmonitor, command(copy "`wdir'\\`modelfile'" "`cdir'\\`modelfile'") ///
				winlogfile(`winlogfile') waitsecs(30)
		}
	}
	else {
		windowsmonitor, command(copy "`wdir'\\`execfile'" "`cdir'\\`execfile'") ///
			winlogfile(`winlogfile') waitsecs(30)
	}

	! copy "`cdir'\`winlogfile'" "`wdir'\winlog1"
	cd "`cdir'"

	if "`rerun'"=="" {
		dis as result "###############################"
		dis as result "###  Output from compiling  ###"
		dis as result "###############################"
		windowsmonitor, command(make "`execfile'") winlogfile(`winlogfile') waitsecs(30)
	}
	! copy `cdir'\`winlogfile' `wdir'
	! copy "`cdir'\`cppfile'" "`wdir'\`cppfile'"
	! copy "`cdir'\`execfile'" "`wdir'\`execfile'"

	dis as result "##############################"
	dis as result "###  Output from sampling  ###"
	dis as result "##############################"

	if `chains'==1 {
		windowsmonitor, command(`cdir'\\`execfile' method=sample `warmcom' `itercom' `thincom' algorithm=hmc `stepcom' `stepjcom' `seedcom' output file="`wdir'\\`outputfile'.csv" data file="`wdir'\\`datafile'") ///
			winlogfile(`winlogfile') waitsecs(30)
	}
	else {
		windowsmonitor, command(for /l %%x in (1,1,`chains') do start /b /w `cdir'\\`execfile' id=%%x method=sample `warmcom' `itercom' `thincom' algorithm=hmc `stepcom' `stepjcom' `seedcom' output file="`wdir'\\`outputfile'%%x.csv" data file="`wdir'\\`datafile'") ///
			winlogfile(`winlogfile') waitsecs(30)
	}
	! copy "`cdir'\`winlogfile'" "`wdir'\winlog3"
	! copy "`cdir'\`outputfile'*.csv" "`wdir'\`outputfile'*.csv"

	windowsmonitor, command(bin\stansummary.exe "`wdir'\\`outputfile'*.csv") winlogfile(`winlogfile') waitsecs(30)

	// reduce csv file
	if `chains'==1 {
		file open ofile using "`wdir'\\`outputfile'.csv", read
		file open rfile using "`wdir'\\`chainfile'", write text replace
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
	}
	else {
		local headerline=1 // flags up when writing the variable names in the header
		file open ofile using "`wdir'\\`outputfile'1.csv", read
		file open rfile using "`wdir'\\`chainfile'", write text replace
		capture noisily {
			file read ofile oline
			while r(eof)==0 {
				if length("`oline'")!=0 {
					local firstchar=substr("`oline'",1,1)
					if "`firstchar'"!="#" {
						if `headerline'==1 {
							file write rfile "`oline',chain" _n
							local headerline=0
						}
						else {
							file write rfile "`oline',1" _n
						}
					}
				}
				file read ofile oline
			}
		}
		file close ofile
		forvalues i=2/`chains' {
			file open ofile using "`wdir'\\`outputfile'`i'.csv", read
			capture noisily {
				file read ofile oline
				while r(eof)==0 {
					if length("`oline'")!=0 {
						local firstchar=substr("`oline'",1,1)
						// skip comments and (because these are chains 2-n)
						// the variable names (which always start with lp__)
						if "`firstchar'"!="#" & "`firstchar'"!="l" {
							file write rfile "`oline',`i'" _n
						}
					}
					file read ofile oline
				}
			}
			file close ofile
		}
		file close rfile
	}

	if "`mode'"=="mode" {
		dis as result "#############################################"
		dis as result "###  Output from optimizing to find mode  ###"
		dis as result "#############################################"
		windowsmonitor, command(`cdir'\\`execfile' optimize data file="`wdir'\\`datafile'" output file="`wdir'\\`outputfile'.csv") ///
			winlogfile(`winlogfile') waitsecs(30)

		// extract mode and lp__ from output.csv
		file open ofile using "`wdir'\\`outputfile'.csv", read
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
		windowsmonitor, command(`cdir'\\`execfile' diagnose data file="`wdir'\\`datafile'") ///
			winlogfile("`wdir'\\`winlogfile'") waitsecs(30)
	}

	// tidy up files
	!del "`winlogfile'"
	!del "wmbatch.bat"
	!del "`modelfile'"
	!copy "`cppfile'" "`wdir'\\`cppfile'"
	!copy "`execfile'" "`wdir'\\`execfile'"
	if "`keepfiles'"=="" {
		!del "`wdir'\\`winlogfile'"
		!del "`wdir'\\wmbatch.bat"
		!del "`wdir'\\`outputfile'*.csv"
	}
	!del "`cdir'\\`cppfile'"
	!del "`cdir'\\`execfile'"

	cd "`wdir'"
}

/*#######################################################
#################### Linux / Mac code ###################
#######################################################*/
else {
	// unless re-running an existing compiled executable, move model to cmdstandir
	if "`rerun'"!="rerun" {
		// check if modelfile already exists in cdir
		capture confirm file "`cdir'/`modelfile'"
		if !_rc {
			// check they are different before copying and compiling
			tempfile working
			shell diff -b "`wdir'/`modelfile'" "`cdir'/`modelfile'" > "`working'"
			tempname wrk
			file open `wrk' using "`working'", read text
			file read `wrk' line
			if "`line'" !="" {
				shell cp "`wdir'/`modelfile'" "`cdir'/`modelfile'"
			}
		}
		else {
			shell cp "`wdir'/`modelfile'" "`cdir'/`modelfile'"
		}
		shell cp "`wdir'/`modelfile'" "`cdir'/`modelfile'"
	}
	else {
		shell cp "`wdir'/`execfile'" "`cdir'/`execfile'"
	}
	cd "`cdir'"

	if "`rerun'"=="" {
		dis as result "###############################"
		dis as result "###  Output from compiling  ###"
		dis as result "###############################"
		shell make "`execfile'"
		// leave modelfile in cdir so make can check need to re-compile
		// shell rm "`cdir'/`modelfile'"
	}

	dis as result "##############################"
	dis as result "###  Output from sampling  ###"
	dis as result "##############################"
	if `chains'==1 {
		shell ./`execfile' method=sample `warmcom' `itercom' `thincom' algorithm=hmc `stepcom' `stepjcom' `seedcom' output file="`wdir'/`outputfile'.csv" data file="`wdir'/`datafile'"
	}
	else {
		shell for i in {1..`chains'}; do ./`execfile' id=\$i method=sample `warmcom' `itercom' `thincom' algorithm=hmc `stepcom' `stepjcom' `seedcom' output file="`wdir'/`outputfile'\$i.csv" data file="`wdir'/`datafile'" & done
	}
	shell bin/stansummary `wdir'/`outputfile'*.csv

	// reduce csv file
	if `chains'==1 {
		file open ofile using "`wdir'/`outputfile'.csv", read
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
	}
	else {
		local headerline=1 // flags up when writing the variable names in the header
		file open ofile using "`wdir'/`outputfile'1.csv", read
		file open rfile using "`wdir'/`chainfile'", write text replace
		capture noisily {
			file read ofile oline
			while r(eof)==0 {
				if length("`oline'")!=0 {
					local firstchar=substr("`oline'",1,1)
					if "`firstchar'"!="#" {
						if `headerline'==1 {
							file write rfile "`oline',chain" _n
							local headerline=0
						}
						else {
							file write rfile "`oline',1" _n
						}
					}
				}
				file read ofile oline
			}
		}
		file close ofile
		forvalues i=2/`chains' {
			file open ofile using "`wdir'/`outputfile'`i'.csv", read
			capture noisily {
				file read ofile oline
				while r(eof)==0 {
					if length("`oline'")!=0 {
						local firstchar=substr("`oline'",1,1)
						// skip comments and (because these are chains 2-n)
						// the variable names (which always start with lp__)
						if "`firstchar'"!="#" & "`firstchar'"!="l" {
							file write rfile "`oline',`i'" _n
						}
					}
					file read ofile oline
				}
			}
			file close ofile
		}
		file close rfile
	}

	if "`mode'"=="mode" {
		dis as result "#############################################"
		dis as result "###  Output from optimizing to find mode  ###"
		dis as result "#############################################"
		shell "`cdir'/`execfile'" optimize data file="`wdir'/`datafile'" output file="`wdir'/`outputfile'.csv"
		// extract mode and lp__ from output.csv
		file open ofile using "`wdir'/`outputfile'.csv", read
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

		// tidy up files
	!rm "`winlogfile'"
	!rm "wmbatch.bat"
	!rm "`modelfile'"
	!cp "`cppfile'" "`wdir'/`cppfile'"
	!cp "`execfile'" "`wdir'/`execfile'"
	if "`keepfiles'"=="" {
		!rm "`wdir'/`outputfile'.csv"
	}
	!rm "`cdir'/`cppfile'"
	!rm "`cdir'/`execfile'"


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
	while "`v1'"!="energy__" {
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
