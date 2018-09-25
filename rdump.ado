
capture program drop rdump
program define rdump
version 11.0
syntax [, Rfile(string) Matrices(string) Globals(string) REPlace]

// set default file name
if "`rfile'"=="" {
	local rfile="R_in.R"
}

// check whether rfile exists already
capture confirm file "`rfile'"
if !_rc & "`replace'"=="" {
	display as error "`rfile' already exists; use the replace option if you want to overwrite it"
	error 602
}
else if !_rc & "`replace'"!="" {
	erase "`rfile'"
}

// open rfile
tempname dataf
quietly file open dataf using "`rfile'", write text replace

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
					if `mval'==. {
						local mval = "NA"
					}
					file write dataf "`mat' <- `mval'" _n
				}
				else {
					file write dataf "`mat' <- c("
					local mcolminusone=`mcol'-1
					forvalues i=1/`mcolminusone' {
						local mval=`mat'[1,`i']
						if `mval'==. {
							local mval = "NA"
						}
						file write dataf "`mval',"
					}
					local mval=`mat'[1,`mcol']
					if `mval'==. {
						local mval = "NA"
					}
					file write dataf "`mval')" _n
				}
			}
			else if `mcol'==1 & `mrow'>1 { // column matrix: write as vector
				file write dataf "`mat' <- c("
				local mrowminusone=`mrow'-1
				forvalues i=1/`mrowminusone' {
					local mval=`mat'[`i',1]
					if `mval'==. {
						local mval = "NA"
					}
					file write dataf "`mval',"
				}
				local mval=`mat'[`mrow',1]
				if `mval'==. {
					local mval = "NA"
				}
				file write dataf "`mval')" _n
			}
			else { // otherwise, write as matrix
				file write dataf "`mat' <- structure(c("
				local mrowminusone=`mrow'-1
				local mcolminusone=`mcol'-1
				forvalues j=1/`mcolminusone' {
					forvalues i=1/`mrow' {
						local mval=`mat'[`i',`j']
						if `mval'==. {
							local mval = "NA"
						}
						file write dataf "`mval',"
					}
				}
				forvalues i=1/`mrowminusone' { // write final column
					local mval=`mat'[`i',`mcol']
					if `mval'==. {
						local mval = "NA"
					}
					file write dataf "`mval',"
				}
				// write final cell
				local mval=`mat'[`mrow',`mcol']
				if `mval'==. {
					local mval = "NA"
				}
				file write dataf "`mval'), .Dim=c(`mrow',`mcol'))" _n
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
			if ${`g'} ==. {
				global `g' = "NA"
			}
			file write dataf "`g' <- ${`g'}" _n
		}
	}
}
file close dataf

end
