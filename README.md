
[![Stan logo](https://github.com/stan-dev/stan/blob/master/logos/stanlogo-main.png?raw=true)](http://mc-stan.org)

**StataStan** is the [Stata](http://www.stata.com) interface to [Stan](http://mc-stan.org). 

Current status
---------
StataStan exists in an alpha-testing form, as a single .do file. We invite all Stata users to test it out and give us feedback, either here on Github, or by email to Robert Grant at [robertstats@live.com](mailto:robertstats@live.com).

Once it has passed testing on all major platforms, it will move to a beta-testing form as .ado and .hlp files. Finally, it will move entirely to a master and develop branch, as with other stan-dev repos, and will be submitted to [SSC](https://ideas.repec.org/s/boc/bocode.html).

There is a single command, -stan-, which will fit a Stan model by Hamiltonian Monte Carlo. You can also ask for the posterior mode, which is found by optimization with the BFGS (or L-BFGS) algorithm. Further options will be added, allowing you to choose sampling algorithms, specify stepsize etc. Then, there will be other Stata commands, allowing CODA-style diagnostics and plotting after a model has been fitted and chains stored. Also, we intend to provide individual 'template' commands for common models such as are supplied in the Stan examples and manual. The aim of this is to make an introduction to using Stan for fast, flexible Bayesian modeling as easy as possible for Stata users. 


Getting Started
----------------
1. Download and install [CmdStan](http://mc-stan.org/cmdstan.html). Make sure you read the installation instructions and platform-specific appendix before installing. In particular, _if you are using 32-bit Windows_, you will need to add a file called 'local' to the 'make' folder before you run the *make* command, which should simply contain the text: *BIT=32*
1. Download and -do- stan.do, either from your do-file editor or the command line
1. Try out the stan-example.do file
1. Try your own data and model. The Stan modelling manual is essential reading here!
1. You can pass your current data (the stuff you see when you typr *browse* in Stata) into Stan, but also you can send matrices and global macros, by specifying their names or typing 'all' in the *matrices* and *globals* options. Unlike BUGS / JAGS, Stan just ignores data that your model doesn't use.

Options
-----------------
* datafile(_filename_): name to write data into in R/S format (in working dir)
* modelfile(_filename_): name of Stan model (that you have already saved), which must end in .stan
  * or you can write into your do-file: two approaches coming soon in the example.do file
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
StataStan has been tested with:
* CmdStan 2.6.2
and Stata versions / flavors:
* 11.2/IC
* 13.1/SE
with operating systems:
* Debian Wheezy Linux (LXDE)
* Windows Vista 32-bit
We would love to hear from any Stata users with other operating systems and older versions of Stata

To-do list
---------------
* WRITE readme and wishlist and move all this text there
* CONSIDER how to avoid re-compiling all the time - apart from working out of cdir (this happens because of copying the modelfile into cdir)
* ADD return stuff like means, 95%CIs, medians and modes
* ADD examples with John Thompson's and Charles Opondo's inline model techniques
* ADD capacity to write initial values from Stata
* ADD stepsize
* ADD number of chains
* ADD nochainfile option
* ADD noprintsummary option
* ADD multicore
* ADD another command that loads chains after the sampling has happened with -nochainfile- or from someone else's Stan output file
* ADD capacity to write arrays of various forms... but how?
* CONSIDER How to avoid piping the output to a file and then displaying that in Windows, which means one has to wait for sampling to finish, and have no idea of progress. It would be nice to provide wintee in some form; see https://code.google.com/p/wintee/
* CONSIDER a compiled line-copying program that reduces output chains without having to go via Stata.
* CONSIDER whether cmdstandir can be set permanently in Stata
* CONSIDER posting means and covariance matrix to e() but I'm not sure what the value of this would be. Could it tempt people into doing strange amalgams of Bayesian model + post-estimation Wald tests? 

Other notes
---------------
* The executable file and .hpp remains under cdir
* Non-existent globals and matrices, and non-numeric globals, get quietly ignored
* Missing values are removed casewise by default
* Users need to take care not to leave output file names as defaults if they have anything called output.csv or modes.csv etc. - these files will be overwritten

Licensing
---------
StataStan is licensed under BSD.   