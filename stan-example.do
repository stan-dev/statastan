// Bernoulli example:

// replace with your cmdstan folder's path
//global cmdstandir "/root/cmdstan/cmdstan-2.6.2" 
global cmdstandir "C:\Users\RLGrant\cmdstan-2.6.2"
global mydir "C:\Users\RLGrant\Dropbox\Software\StataStan"

cd "${mydir}"
// get the Bernoulli.stan file 
if lower("$S_OS")=="windows" {
	!copy ${cmdstandir}\examples\bernoulli\bernoulli.stan ${mydir}\bernoulli.stan
	!copy ${cmdstandir}\examples\bernoulli\bernoulli.stan ${cmdstandir}\bernoulli.stan
}
else {
	!cp ${cmdstan}/examples/bernoulli/bernoulli.stan ${mydir}/bernoulli.stan
	!cp ${cmdstan}/examples/bernoulli/bernoulli.stan ${cmdstandir}/bernoulli.stan
}
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)
stan y, modelfile("bernoulli.stan") cmd("$cmdstandir") globals("N") load mode
