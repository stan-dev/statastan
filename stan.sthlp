{smcl}
{* *! version 1.1  26feb2016}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "windowsmonitor" "help windowsmonitor"}{...}
{viewerjumpto "Syntax" "stan##syntax"}{...}
{viewerjumpto "Description" "stan##description"}{...}
{viewerjumpto "Options" "stan##options"}{...}
{viewerjumpto "Remarks" "stan##remarks"}{...}
{viewerjumpto "Examples" "stan##examples"}{...}
{title:Title}

{phang}
{bf:stan} {hline 2} Use Stan software for Bayesian modeling: translate a Stan model to C++, compile to an executable file, sample from the posteriors using this, and display summaries.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:stan}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt data:file(filename)}}destination text file for data on their way to Stan{p_end}
{synopt:{opt model:file(filename)}}.stan file containing the Stan model, or location of text file into which the model will be written{p_end}
{synopt:{opt inline}}read the .stan model from a comment block insid ethe do-file{p_end}
{synopt:{opt thisfile(filename)}}the name (and path, if required) of the current do-file, if inline has been specified (see Remarks){p_end}
{synopt:{opt init:sfile(filename)}}text file in R / S-plus format containing initial values{p_end}
{synopt:{opt diag:nose}}run Stan's diagnostics{p_end}
{synopt:{opt output:file(filename)}}destination text file for Stan outputs{p_end}
{synopt:{opt chain:file(filename)}}destination for Stan chains in CSV format{p_end}
{synopt:{opt mode}}run Stan's optimization to find posterior modes{p_end}
{synopt:{opt modesfile(filename)}}destination text file for Stan estimation of modes{p_end}
{synopt:{opt winlog:file(filename)}}temporary file to hold Windows output (see {cmd:windowsmonitor}){p_end}
{synopt:{opt seed}}random number generator seed for Stan{p_end}
{synopt:{opt warmup(integer)}}number of warmup iterations{p_end}
{synopt:{opt iter(integer)}}number of iterations to retain after warmup{p_end}
{synopt:{opt thin(integer)}}thinning of iterations: retain one out of every {it:thin}{p_end}
{synopt:{opt sk:ipmissing}}remove missing data observation-wise before sending to Stan{p_end}
{synopt:{opt mat:rices(string)}}list of matrices to send to Stan, or "all" to send all current matrices{p_end}
{synopt:{opt gl:obals(string)}}list of globals to send to Stan, or "all" to send all current global macros{p_end}
{synopt:{opt keepf:iles(integer)}}keep all files produced along the way; if not specified, the model file, C++ file, executable file, chains file and (if produced) modes file will be retained{p_end}
{synopt:{opt stepsize(integer)}}HMC stepsize, default 1 (see Stan manual){p_end}
{synopt:{opt stepsizejitter(integer)}}HMC stepsize jitter, default 0 (see Stan manual){p_end}


{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} and {cmd:fweight}s are not allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:stan} is the Stata interface to the open-source Bayesian software Stan, which works by translating a simple model language to C++ and compiling that.
Stan utilises Hamiltonian Monte Carlo through the No U-Turn Sampler (NUTS) to provide much faster and more stable sampling than could be achieved with the Metropolis-Hastings algorithm or the Gibbs sampler (these are the methods implemented in BUGS, JAGS and {cmd:bayesmh}).
In keeping with other Stan interfaces, it is known as StataStan when regarded as a package along with {help windowsmonitor} and the various {cmd:stan_*} commands to populate specific models.
In essence, it is a wrapper for the CmdStan command-line interface.
Data and results are passed between Stata and Stan via text files.

{pstd}
To use {cmd:stan}, you will need to have CmdStan installed from http://mc-stan.org/interfaces/cmdstan.html where you will also find instructions on installation and checking that you can compile C++ programs.
The Stan programming manual and quick-start guide is at http://mc-stan.org/documentation/

{pstd}
If you are using {cmd:stan} on a Windows computer, you will need to install {cmd:windowsmonitor} too.

{pstd}
The variables listed in {it:varlist} will be sent to Stan, along with any global macros and matrices that are named in the relevant options.
If the option {it:skipmissing} is included, missing data will be excluded observation-wise, which means that each variable becomes a vector containing only the non-missing values.
This is potentially useful as a way of sending vectors of different lengths to Stan, but should be used with great caution if the current data contain missing values.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt datafile} name (and path if desired) of the text file to contain the data (variables, globals and matrices) in R / S-plus format (default is statastan_data.R in the working directory)

{phang}
{opt modelfile} name (and path if desired) of the text file to contain the .stan model code (default is statastan_model.stan in the working directory)

{phang}
{opt inline} indicates that Stata should read the Stan model from a comment block inside the current do-file, scanning lines until it finds a comment block that begins "data {"

{phang}
{opt thisfile} name (and path if required) of the current do-file; in combination with {it:inline}, this will read the do-file using {cmd: file read}; if it is omitted but {it:inline} is specified, Stata will examine the temporary directory (type {cmd:display c(tmpdir)} to find this) for the latest file beginning ST or STD, depending on your operating system, which should contain the code that Stata is attempting to {cmd:do}.

{phang}
{opt initsfile} text file containing initial values to send to Stan; in most cases, these do not have to be specified as convergence is faster and more likely than under Metropolis-Hastings or Gibbs

{phang}
{opt diagnose} after sampling, run Stan's diagnostics and display the results

{phang}
{opt outputfile} name (and path if required) for a text file to receive the outputs from Stan (default is output.csv in the working directory)

{phang}
{opt chainfile} name (and path if required) for a CSV formatted file to hold the individual values from iterations of the Stan sampling; this can be read back into Stata by specifying the {it:load} option (default is statastan_chains.csv in the working directory)

{phang}
{opt mode} use Stan's optimize function to find the modes of the posterior distributions by the L-BFGS algorithm; the default shows the means and medians

{phang}
{opt modesfile} name (and path if required) of a text file to hold output from Stan optimization if the {cmd:mode} option has been specified (default is modes.csv in the working directory)

{phang}
{opt winlogfile} name (and path if required) of a text file to hold output from Windows, so it can be displayed in almost-real-time using {cmd:windowsmonitor} (default is winlog.txt in the working directory)

{phang}
{opt seed} integer random number generator seed to pass to Stan (it is not used in Stata)

{phang}
{opt warmup} number of iterations to discard before storing chains; default is 1000

{phang}
{opt iter} number of iterations to retain after warmup; default is 1000

{phang}
{opt thin} to reduce autocorrelation and the need to store excessively long chains, save only every nth sample

{phang}
{opt skipmissing} remove missing values from {it:varlist} observation-wise before sending to Stan; use with caution

{phang}
{opt matrices} list of matrix names to send to Stan, or "all" to send all

{phang}
{opt globals} list of matrix names to send to Stan, or "all" to send all

{marker remarks}{...}
{title:Remarks}

{pstd}
StataStan is maintained and collaboratively developed at https://github.com/stan-dev/statastan where you can find the latest versions
and reports of issues that need to be fixed - and you can suggest improvements.
The Stan developers are listed at http://mc-stan.org/team

{pstd}
There are four ways of passing the model to Stan. Opinions differ on whether it is preferable to have the model in a separate .stan file, or inside the do-file. These are shown in the examples below.



{marker examples}{...}
{title:Examples}

// Bernoulli example:

// make your data
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)

// replace with your cmdstan folder's path
global cmdstandir "/root/cmdstan/cmdstan-2.6.2"

// here we present four different ways of combining the Stan model with your do-file

//##############################################
// Version 1: write a separate model file

/* call Stan, providing the modelfile option - no need to do anything else but you must
keep the .do and .stan files together for posterity */
stan y, modelfile("bernoulli.stan") cmd("$cmdstandir") globals("N")

//###########################################

/* Version 2: specify the model inline in a comment block, naming THIS do-file in the
thisfile option (the John Thompson method, adopted from his commands for interfacing with BUGS) */

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
   do-file name and path, but might not work sometimes if c(tmpdir) is crowded,
   or especialy if you have more than one instance of Stata running */

// here's the model:
/*
data {
  int<lower=0> N;
  int<lower=0,upper=1> y[N];
}}
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

/* Version 4: specify the model inline, so it is written to the
 text file of your choosing but everything is controlled from the do-file
 (the Charles Opondo method) */

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
