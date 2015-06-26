// Bernoulli example:

// replace with your cmdstan folder's path
global cmdstandir "/root/cmdstan/cmdstan-2.6.2"

cd "$cmdstandir"

//##############################################
// Version 1: separate model file

// get the Bernoulli.stan file
if lower("$S_OS")=="windows" {
	!copy examples\bernoulli\bernoulli.stan bernoulli.stan
}
else {
	!cp ./examples/bernoulli/bernoulli.stan bernoulli.stan
}

// make your data
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)

// call Stan
stan y, modelfile("bernoulli.stan") cmd("$cmdstandir") globals("N")


//###########################################

// Version 2: specify the model inline, the John Thompson way (in a comment block),
// naming THIS do-file:

// make your data
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)

// here's the model:
/*
data {
  int<lower=0> N;
  int<lower=0,upper=1> y[N];
}
parameters {
  real<lower=0,upper=1> theta;
}
model {
  theta ~ beta(1,1);
  for (n in 1:N)
    y[n] ~ bernoulli(theta);
}
*/

// call Stan with the inline and thisfile options
stan y, inline thisfile("/root/git/statastan/stan-example.do") modelfile("inline-bernoulli.stan") ///
	cmd("$cmdstandir") globals("N") load mode

// or let StataStan go looking for it in c(tempdir)
// (this saves you typing in the do-file name and path, but might not work sometimes)
stan y, inline modelfile("inline-bernoulli.stan") ///
	cmd("$cmdstandir") globals("N") load mode
	
//###############################################################

// Version 4: specify the model inline, the Charles Opondo way:

// make the data
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)

// write the model from Stata into a plain text file
tempname writemodel
file open `writemodel' using "mystanmodel.stan", write replace
#delimit ;
foreach line in
	"data { "
	"int<lower=0> N; "
	"int<lower=0,upper=1> y[N];"
	"} "
	"parameters {"
	"real<lower=0,upper=1> theta;"
	"} "
	"model {"
	"theta ~ beta(1,1);"
	"for (n in 1:N) "
	"y[n] ~ bernoulli(theta);"
	"}"
{;
	#delimit cr
	file write `writemodel' "`line'" _n
}
file close `writemodel'

// call Stan
stan y, modelfile("mystanmodel.stan") cmd("$cmdstandir") globals("N") load mode


/* there are three reasons we prefer the Opondo method:
	1. We can't rule out other processes making SD* files in the tmpdir while
		Stata is running. In fact, some versions of Stata under some
		operating systems write S* instead.
	2. Naming the do-file inside itself is a particularly perverse form of
	hard-coding. It is likely to cause you trouble later.
	3. Either version of Thompson's method (as I implement it) will
		adopt the first comment block it finds that begins with the word
		"data" as the Stan model. That could pick the wrong thing.
Nevertheless, I have great admiration for Prof Thompson's achievements interfacing with BUGS
	with admiration, and do not intend to detract from any of that incredibly
	useful body of work.
Note, however, that if your Stan model somehow required quotes, then you would
	have to make sure the outer quotes in this do-file were different. Stata's ability
	to work with either ' or " is a wonderful thing that you only appreciate once
	you've had to program Stata to write HTML (vel sim).

Also, note that Stigler's law of eponymy is hard at work here. */
