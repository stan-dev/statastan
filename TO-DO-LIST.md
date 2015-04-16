Known problems
---------------
* If load or mode option is specified and the compiling fails, it might still find a "statastan_chains.csv" or other files and carry on producing outputs.

To-do list
---------------
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
