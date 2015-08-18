
[![Stan logo](https://github.com/stan-dev/stan/blob/master/logos/stanlogo-main.png?raw=true)](http://mc-stan.org)

**StataStan** is the [Stata](http://www.stata.com) interface to [Stan](http://mc-stan.org).

Current status
---------
StataStan exists in an alpha-testing form, as a single stan.do file. We invite all Stata users to test it out and give us feedback, either here on Github, or by email to Robert Grant at [robertstats@live.com](mailto:robertstats@live.com).

Once it has passed testing on all major platforms, it will move to a beta-testing form as .ado and .hlp files. Finally, it will move entirely to a master and develop branch, as with other stan-dev repos, and will be submitted to [SSC](https://ideas.repec.org/s/boc/bocode.html).

There is a single command, -stan-, which will fit a Stan model by Hamiltonian Monte Carlo. You can also ask for the posterior mode, which is found by optimization with the BFGS (or L-BFGS) algorithm. Further options will be added, allowing you to choose sampling algorithms, specify stepsize etc. Then, there will be other Stata commands, allowing CODA-style diagnostics and plotting after a model has been fitted and chains stored. Also, we intend to provide individual 'template' commands for common models such as are supplied in the Stan examples and manual. The aim of this is to make an introduction to using Stan for fast, flexible Bayesian modeling as easy as possible for Stata users, so that you could type something like:

    stanxtmelogit alive i.heartattacktype delay, priors(norm(10 10)) || hospital, re(gaussian) priors(unif(0.1 50))

and get a multilevel logistic regression for survival predicted by heart attack type and delay, clustered by hospital. The fixed effect parameters all have prior ~N(10,100), the random intercept is Gaussian and its standard deviation has a uniform weakly informative prior from 0.1 to 50.

Getting Started
----------------
1. Download and install [CmdStan](http://mc-stan.org/cmdstan.html). Make sure you read the installation instructions and platform-specific appendix before installing. In particular, _if you are using 32-bit Windows_, you will need to add a file called 'local' to the 'make' folder before you run the *make* command, which should simply contain the text: *BIT=32*
1. Download and -do- stan.do, either from your do-file editor or the command line
1. Try out the different examples in the stan-example.do file
1. Try your own data and model. The Stan modelling manual is essential reading here!
1. You can pass your current data (the stuff you see when you type *browse* in Stata) into Stan, but also you can send matrices and global macros, by specifying their names or typing 'all' in the *matrices* and *globals* options. Unlike BUGS / JAGS, Stan just ignores data that your model doesn't use.

Options
-----------------
* datafile(_filename_): name to write data into in R/S format (in working dir)
* modelfile(_filename_): name of Stan model (that you have already saved), which must end in .stan
* inline: read in the model from a comment block in your current do-file. If you specify modelfile, that name will be given to the model when it is saved, and again it must end with .stan
* thisfile: optional, to use with inline; gives the path and name of the current active do-file, used to locate the model inline. If thisfile is omitted, Stata will look at the most recent SD (Linux/Mac) or STD (Windows) file in c(tmpdir). This should work most of the time but other processes running on your computer could interfere with c(tmpdir). See the stan-example.do file for our preferred method for inline model code.
* initsfile(_filename_): name of initial values file in R/S that you have already saved
* load: read iterations into Stata
* diagnose: run gradient diagnostics
* outputfile(_filename_): name of file to contain Stan output
* modesfile(_filename_): CSV file to contain posterior modes and BFGS log-probs
  * Careful not to mix this up with modelfile!
* chainfile(_filename_): name of CSV file to contain chain (trimmed version of output.csv); to support parallel processing, numbers will be added to this (but not yet)
* winlogfile(_filename_): in Windows, where to store stdout & stderr before displaying on the screen (but see to-do list)
* seed(_integer_): RNG seed
* warmup(_integer_): number of warmup (burn-in) steps, default 1000
* iter(_integer_): number of samples to retain after warmup, default 1000
* thin(_integer_): keep every nth sample, for autocorrelation, default 1
* cmdstandir(_path_): CmdStan path (not including /bin)
* mode: run Stan's optimize funtion to get posterior mode
* skipmissing: omit missing values variablewise to Stan (caution required!!!)
* matrices("_namelist_"): list of matrices to write, or 'all'
* globals("_namelist_"): list of global macro names to write, or 'all'

Testing
-----------------
StataStan has been tested with CmdStan 2.6.2 and 2.7.0, Stata versions from 11.2 to 14.0, and Stata flavors IC and SE. We have not added multicore capacity yet, but it is on the to-do list and is easy to do (see Stan manual).

It seems very stable on Linux and Windows, but we need some feedback from Mac users (please), and we'd love to hear if it works with Windows 10 or older versions of Stata.

Other notes
---------------
* A copy of your .stan, .hpp and executable files remain under the CmdStan directory. This helps avoid unnecessary re-compiling, but you might want to clear them out from time to time. The .stan file gets copied into your working directory, and the data and output files get moved there.
* Non-existent globals and matrices, and non-numeric globals, get quietly ignored
* Missing values are removed casewise by default (but you can change this)
* Users need to take care not to leave output file names as defaults if they have anything precious called output.csv or modes.csv etc. - these files will be overwritten

Licensing
---------
StataStan is licensed under BSD.