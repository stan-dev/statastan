cd "C:\Users\RLGrant\Dropbox\Software\StataStan\stan_examples"
use "schools.dta", clear
qui tab school
global M=r(r)
qui count
global N=r(N)
stan_schools Y VR1 VR2 Gender LRT, rslopes(denom2 denom3 sgender) ///
	globals("N M") clusterid(school) ///
	stanopts(cmd("C:/Users/RLGrant/cmdstan-2.6.2"))
