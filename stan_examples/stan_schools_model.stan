# A Bayesian hierarchical linear regression model
# following the BUGS 'Schools' example,
# written using stan_schools (see https://github.com/stan-dev/statastan)

data {
	int<lower=0> N;
	int<lower=0> M;
	int school[N];
	real VR1[N];
	real VR2[N];
	real Gender[N];
	real LRT[N];
	real denom2[N];
	real denom3[N];
	real sgender[N];
	real Y[N];
	cov_matrix[4] R;
}
transformed data {
	vector[4] gamma_mu;
	cov_matrix[4] gamma_Sigma;
	cov_matrix[4] invR;
	invR <- inverse(R);
	for (i in 1:4) gamma_mu[i] <- 0;
	for (i in 1:4) for (j in 1:4) gamma_Sigma[i, j] <- 0;
	for (i in 1:4) gamma_Sigma[i, i] <- 100;
}
parameters {	real beta[4];
	vector[4] alpha[M];
	vector[4] gamma;
	cov_matrix[4] Sigma;
	real<lower=0> sde;
}
model {
	real Ymu[N];
	for(p in 1:N) {
		Ymu[p] <- alpha[school[p], 1]
			 + alpha[school[p],2]*denom2[p]
			 + alpha[school[p],3]*denom3[p]
			 + alpha[school[p],4]*sgender[p]
			 + beta[1]*VR1[p]
			 + beta[2]*VR2[p]
			 + beta[3]*Gender[p]
			 + beta[4]*LRT[p]
			;
	}

	Y ~ normal(Ymu, sde); 

	# Priors for fixed effects:
	beta ~ normal(0,100);
	sde ~ normal(0,100);

	# Priors for random coefficients:
	for (m in 1:M) alpha[m] ~ multi_normal(gamma, Sigma);
	# Hyper-priors:
	gamma ~ multi_normal(gamma_mu, gamma_Sigma);
	Sigma ~ inv_wishart(4, invR);
}
