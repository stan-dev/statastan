// Bernoulli example:

// replace with your cmdstan folder's path
global cmdstandir "C:\Users\RLGrant\cmdstan-2.6.2" 

cd "$cmdstandir"
// get the Bernoulli.stan file 
if lower("$S_OS")=="windows" {
	!copy examples\bernoulli\bernoulli.stan bernoulli.stan
}
else {
	!cp examples\bernoulli\bernoulli.stan bernoulli.stan
}
clear
set obs 10
gen y=0
replace y=1 in 2
replace y=1 in 10
count
global N=r(N)
stan y, modelfile("bernoulli.stan") cmd("$cmdstandir") globals("N") load mode
