To-do list
---------------
* ADD comparison of modelfile in wdir & cdir to avoid re-compiling
* WRITE Stata .sthlp
* ADD return stuff like means, 95%CIs, medians and modes
* ADD capacity to write initial values from Stata
* ADD stepsize
* WRITE quick start guide
* WRITE vignette
* WRITE manual (same as .sthlp but using Stata manual LaTeX template)
* ADD number of chains (parallel if possible, series otherwise, and stiched together at the end)
* ADD nochainfile option
* ADD noprintsummary option
* CONSIDER Stata/MP
* ADD another command that loads chains after the sampling has happened with -nochainfile- or from someone else's Stan output file
* ADD capacity to write arrays of various forms... but Stata doesn't have such structures
* CONSIDER a compiled line-copying program that reduces output chains without having to go via Stata (though this is not a problem for speed so far)
* CONSIDER whether cmdstandir can be set permanently in Stata
* CONSIDER posting means and covariance matrix to e() but I'm not sure what the value of this would be. Could it tempt people into doing strange amalgams of Bayesian model + post-estimation Wald tests?
* Make into Stata package
