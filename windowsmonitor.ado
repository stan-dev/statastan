
capture program drop windowsmonitor
program define windowsmonitor
version 11.0

syntax ,COMMAND(string asis) [ WINLOGfile(string asis) waitsecs(integer 10) ]

// stop if operating system is not Windows
if lower("$S_OS")!="windows" {
	dis as error "windowsmonitor can only run under a Windows operating system"
	error 601
}

// default winlogfile
if ("`winlogfile'"=="") {
	tempfile winlogfile
}
else {
	// delete any existing winlogfile
	! del "`winlogfile'"
}

// construct batch file
tempfile wmbatch
capture file close sb
capture noisily { // to ensure files are closed
//	file open sb using "`wmbatch'", write text replace
	file open sb using "wmbatch.bat", write text replace

	file write sb `"`macval(command)'"' _n
	file write sb "echo Finished!" _n
}
capture file close sb

// issue command, piping output to winlogfile
//winexec "`wmbatch'" > "`winlogfile'"
winexec "wmbatch.bat" > "`winlogfile'" 2>&1

// wait up to waitsecs seconds for winlogfile to appear
local loopcount=0
capture confirm file "`winlogfile'"
while _rc & (`loopcount'<`waitsecs') {
	sleep 1000
	capture confirm file "`winlogfile'"
	local ++loopcount
}
if _rc {
	dis as error "No output detected from Windows after `waitsecs' seconds"
	error 601
}

// start reading from winlogfile
capture file close sout
capture noisily { // to ensure files are closed
file open sout using "`winlogfile'", read text
local linecount=0
while(`"`macval(lastline)'"'!="Finished!") {
    sleep 2000
	// display everything after the linecount-th line
	file seek sout 0
	file read sout line
	local newlinecount=1
	if `newlinecount'>`linecount' {
		dis as result `"`macval(line)'"'
	}
	while r(eof)==0 {
		file read sout line
		if r(eof)==0 {
			local ++newlinecount
			if `newlinecount'>`linecount' {
				dis as result `"`macval(line)'"'
			}
			local lastline=`"`macval(line)'"'
		}
	}
	local linecount=`newlinecount'
}
}
capture file close sout
end
