{smcl}
{* *! version 0.0.2  9jul2016}{...}
{vieweralsosee "Stan" "help stan"}{...}
{viewerjumpto "Syntax" "write_dump##syntax"}{...}
{viewerjumpto "Description" "write_dump##description"}{...}
{viewerjumpto "Options" "write_dump##options"}{...}
{viewerjumpto "Remarks" "write_dump##remarks"}{...}
{viewerjumpto "Examples" "write_dump##examples"}{...}
{title:Title}

{phang}
{bf:write_dump} {hline 2} Write data in the R dump format.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:write_dump}
[anything]
{cmd:using}
filename
[{cmd:,}
{opt replace}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:write_dump} writes every {it:numeric} scalar, global macro, matrix and
variable in memory to {input:filename} in the R dump format, if {input:anything}
is not specified. If {input:anything} is specified, then only those will be
written.

{pstd}
Non-numeric variables are skipped with a warning message; missing values are
converted to NaN. Non-numeric scalars and globals are silently ignored. Anything
that is not a scalar, global macro, matrix, or variable is also ignored. 

{pstd}
No extension is added to {input:filename}. The recommended extension for a dump
file is .data.R.


{marker options}{...}
{title:Options}

{pstd}
{opt replace} specifies that {input:filename} be overwritten. The default
is to append the data.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:write_dump} is written for use with the StataStan interface. For more
detail, see {browse github.com/stan-dev/statastan}.


{marker examples}{...}
{title:Examples}

{bf: // example 1}
{pstd}
{input:anything} is not specified; the default is to dump all numeric
scalars, globals, matrices, and variables in memory.
With the {input:replace} option, the file test_dump.data.R will be overwritten,
if it exists.
{p_end}
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. write_dump using test_dump.data.R, replace}{p_end}

{bf: // example 2}
{pstd}
Only {input:price mpg headroom} will be written. {input:this_doesnt_exist} is
simply ignroed.
{p_end}
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. write_dump price mpg headroom this_doesnt_exist using}
       {cmd:test_dump.data.R, replace}{p_end}

{bf: // example 3}
{pstd}
Same as example 1, but matrices {input:A} and {input:B}, the scalar
{input:constant}, and the macros {input:N} and {input:M} are also written to
the file.
{p_end}
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. matrix A = (1, 2\ 3, 4)}{p_end}
{phang}{cmd:. matrix B = (5, 6, 7\ 8, 9, 10)}{p_end}
{phang}{cmd:. matrix dir}{p_end}
{phang}{cmd:. scalar constant = 123}{p_end}
{phang}{cmd:. scalar dir}{p_end}
{phang}{cmd:. global N = 101}{p_end}
{phang}{cmd:. global M = 202}{p_end}
{phang}{cmd:. macro dir}{p_end}
{phang}{cmd:. write_dump using test_dump.data.R, replace}{p_end}
