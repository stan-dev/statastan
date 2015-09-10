version 14.0
capture program drop stan_schools
program define stan_schools
	syntax varlist [if] [in] [, MODELfile(string asis) ///
								Clusterid(varname) ///
								RSlopes(varlist) ///
								GLOBALS(string asis) ///
								BETAPriors(string asis) ///
								HETvar(varname) ///
								THETAPrior(string asis) ///
								PHIPrior(string asis) ///
								SDEPrior(string asis) ///
								GAMMAPrior(string asis) ///
								SIGMAPrior(string asis) ///
								STANOpts(string asis)]
	tokenize `varlist'
	// get depvar
	local depvar="`1'"
	macro shift
	// parse varlist, count indep vars
	local nbetas=1
	while "``nbetas''"!="" {
		local x_`nbetas'="``nbetas''" // we'll use these names in the stan model
		local ++nbetas // count how many coefficients we will need
	}
	local --nbetas // reject the last one
	
	if "`rslopes'"!="" {
		// parse xj, count random slopes
		tokenize `rslopes'
		local nalphas=1
		while "``nalphas''"!="" {
			local z_`nalphas'="``nalphas''" // we'll use these names in the stan model
			local ++nalphas // count how many coefficients we will need (+ intercept)
		}
		// we don't reduce nalphas because of the random intercept
	}
	
dis as result "nalphas: `nalphas'"
dis as result "nbetas: `nbetas'"
	
	// defaults
	foreach pp in betapriors thetaprior phiprior sdeprior {
		if "``pp''"=="" {
			local `pp'="normal(0,100)"
		}
	}
	if "`modelfile'"=="" {
		local modelfile="stan_schools_model.stan"
	}

	// count the clusters
	qui tab `clusterid'
	global M=r(r)
	// count the observations
	qui count
	global N=r(N)
	
	// open modelfile
	tempname mf
	file open `mf' using `modelfile', write text replace
	file write `mf' "# A Bayesian hierarchical linear regression model" _n
	file write `mf' "# following the BUGS 'Schools' example," _n
	file write `mf' "# written using stan_schools (see https://github.com/stan-dev/statastan)" _n _n
	file write `mf' "data {" _n
	file write `mf' _tab "int<lower=0> N;" _n
	file write `mf' _tab "int<lower=0> M;" _n
	file write `mf' _tab "int `clusterid'[N];" _n
	forvalues i=1/`nbetas' {
		file write `mf' _tab "real `x_`i''[N];" _n
	}
	if `nalphas'>1 {
		local slopes=`nalphas'-1 // random intercept has no data
		forvalues i=1/`slopes' {
			file write `mf' _tab "real `z_`i''[N];" _n
		}
	}
	file write `mf' _tab "real `depvar'[N];" _n
	file write `mf' _tab "cov_matrix[`nalphas'] R;" _n
	file write `mf' "}" _n
	file write `mf' "transformed data {" _n
	file write `mf' _tab "vector[`nalphas'] gamma_mu;" _n
	file write `mf' _tab "cov_matrix[`nalphas'] gamma_Sigma;" _n
	file write `mf' _tab "cov_matrix[`nalphas'] invR;" _n
	file write `mf' _tab "invR <- inverse(R);" _n
	file write `mf' _tab "for (i in 1:`nalphas') gamma_mu[i] <- 0;" _n
	file write `mf' _tab "for (i in 1:`nalphas') for (j in 1:`nalphas') gamma_Sigma[i, j] <- 0;" _n
	file write `mf' _tab "for (i in 1:`nalphas') gamma_Sigma[i, i] <- 100;" _n
	file write `mf' "}" _n
	file write `mf' "parameters {"
	file write `mf' _tab "real beta[`nbetas'];" _n
	file write `mf' _tab "vector[`nalphas'] alpha[M];" _n
	file write `mf' _tab "vector[`nalphas'] gamma;" _n
	file write `mf' _tab "cov_matrix[`nalphas'] Sigma;" _n
	// if hetvar, include formula for log-variance
	if "`hetvar'"!="" {
		file write `mf' _tab "real theta;" _n
		file write `mf' _tab "real phi;" _n
	}
	// if not, SD of error
	else {
		file write `mf' _tab "real<lower=0> sde;" _n
	}
	file write `mf' "}" _n
	file write `mf' "model {" _n
	file write `mf' _tab "real Ymu[N];" _n
	file write `mf' _tab "for(p in 1:N) {" _n
	// write the linear predictor
	file write `mf' _tab _tab "Ymu[p] <- alpha[`clusterid'[p], 1]" _n
		if `nalphas'>1 {
			forvalues i=1/`slopes' {
				local iplus=`i'+1
				file write `mf' _tab(3) " + alpha[`clusterid'[p],`iplus']*`z_`i''[p]" _n
			}
		}
		forvalues i=1/`nbetas' {
			file write `mf' _tab(3) " + beta[`i']*`x_`i''[p]" _n
		}
		file write `mf' _tab(3)";" _n
	file write `mf' _tab "}" _n _n
	// heteroskedastic or not?
	if "`hetvar'"!="" {
		file write `mf' _tab "`depvar' ~ normal(Ymu, exp(-.5*(theta + phi*`hetvar'))); " _n _n
	}
	else {
		file write `mf' _tab "`depvar' ~ normal(Ymu, sde); " _n _n
	}
	file write `mf' _tab "# Priors for fixed effects:" _n
	file write `mf' _tab "beta ~ `betapriors';" _n
	if "`hetvar'"!="" {
		file write `mf' _tab "theta ~ `thetaprior';" _n
		file write `mf' _tab "phi ~ `phiprior';" _n _n
	}
	else {
		file write `mf' _tab "sde ~ `sdeprior';" _n _n
	}
	// at present, you can't change the alpha priors
	file write `mf' _tab "# Priors for random coefficients:" _n
	file write `mf' _tab "for (m in 1:M) alpha[m] ~ multi_normal(gamma, Sigma);" _n
	file write `mf' _tab "# Hyper-priors:" _n
	file write `mf' _tab "gamma ~ multi_normal(gamma_mu, gamma_Sigma);" _n
	file write `mf' _tab "Sigma ~ inv_wishart(`nalphas', invR);" _n
	file write `mf' "}" _n
	file close `mf' 

	// stan with stanopts
	stan `varlist' `rslopes' `clusterid', globals("`globals'") ///
		modelfile("`modelfile'") `stanopts'
	
end

/* To do:
	allow a sequence of different betapriors
	allow i. notation
	option to feed data into previously compiled model
	initial values
	nori: no random intercept
	
   Notes:
	I maintain the same Greek latters as in BUGS, despite them being unusual in places
	We assume hetvar is in varlist
	You have to specify modelfile in modelfile() OR in stanopts()
*/
