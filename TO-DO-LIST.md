To-do list
---------------

* Return summary stats like means, 95%CIs, medians and modes to Stata in r()
* ADD noprintsummary option
* WRITE quick start guide
* WRITE vignette
* WRITE manual (same as .sthlp but using Stata manual LaTeX template)
* CONSIDER Stata/MP
* ADD another command that loads chains after the sampling has happened with -nochainfile- or from someone else's Stan output file
* ADD capacity to write arrays of various forms... but Stata doesn't have such structures... could go via Mata
* CONSIDER moving the line-copying that reduces outputfile(s) to chainsfile into OS or even Stan so it doesn't have to go via Stata (though this is not a problem for speed so far)
* CONSIDER whether cmdstandir can be set permanently in Stata
* CONSIDER posting means and covariance matrix to e() but I'm not sure what the value of this would be. Could it tempt people into doing strange amalgams of Bayesian model + post-estimation Wald tests?
* REMOVE stepsize_jitter (deprecating in Stan v3)
