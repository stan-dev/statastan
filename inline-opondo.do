tempname fout
file open `fout' using "mystanmodel.stan", write replace
#delimit ;
foreach line in
	"data {"
	"   int N;"
	"   real x[N];"
	"}"
	"parameters{"
	"   real mu;"
	"}"
{;
	#delimit cr
	file write `fout' "`line'" _n
}
file close `fout'
//stan ...	
