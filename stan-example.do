// Bernoulli example:

// replace with your cmdstan folder's path
global cmdstandir "/root/cmdstan/cmdstan-2.6.2"

// here we present four different ways of combining the Stan model with your do-file


//##############################################
// Version 1: write a separate model file

/* For this example, we can just copy the Bernoulli.stan file
   from the examples folder, but you would typically write your
   .stan file in a text editor and save it */
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

// call Stan, providing the modelfile option
stan y, modelfile("bernoulli.stan") cmd("$cmdstandir") globals("N")


//###########################################

/* Version 2: specify the model inline, the John Thompson way (in a comment block),
   naming THIS do-file in the thisfile option */

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

// call Stan with the inline and thisfile options.
// modelfile now tells it where to save your model
stan y, inline thisfile("/root/git/statastan/stan-example.do") ///
	modelfile("inline-bernoulli.stan") ///
	cmd("$cmdstandir") globals("N") load mode


//###############################################################

/* Version 3: use the comment block, but don't provide thisfile - Stata
   will go looking for it in c(tmpdir), which saves you typing in the
   do-file name and path, but might not work sometimes */

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

stan y, inline modelfile("inline-bernoulli.stan") ///
	cmd("$cmdstandir") globals("N") load mode
	
//###############################################################

/* Version 4: specify the model inline, the Charles Opondo way, so
   it is written to the text file of your choosing but everything is 
   controlled from the do-file */

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
	"  int<lower=0> N; "
	"  int<lower=0,upper=1> y[N];"
	"} "
	"parameters {"
	"  real<lower=0,upper=1> theta;"
	"} "
	"model {"
	"  theta ~ beta(1,1);"
	"  for (n in 1:N) "
	"    y[n] ~ bernoulli(theta);"
	"}"
{;
	#delimit cr
	file write `writemodel' "`line'" _n
}
file close `writemodel'

// call Stan
stan y, modelfile("mystanmodel.stan") cmd("$cmdstandir") globals("N") load mode


/* there are two reasons why we prefer the Opondo method:
	1. We can't rule out other processes making SD* or STD* files in the 
		tmpdir while Stata is running (or indeed other parts of your do-file(s)
	2. Naming the do-file inside itself is a particularly perverse form of
	hard-coding. It is likely to cause you trouble later.
Nevertheless, we admire Prof Thompson's achievements interfacing with BUGS, and 
	do not intend to detract from any of that useful body of work.
Remember, if your Stan model somehow required quotes, then you would
	have to make sure you use Stata compound quotes 
	(see http://www.stata.com/meeting/5uk/program/quotes1.html)
Also, note that Stigler's law of eponymy is hard at work here. */
