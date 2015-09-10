{smcl}
{* *! version 1.0  08sep2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "stan" "help stan"}{...}
{vieweralsosee "windowsmonitor" "help windowsmonitor"}{...}
{viewerjumpto "Syntax" "stan_schools##syntax"}{...}
{viewerjumpto "Description" "stan_schools##description"}{...}
{viewerjumpto "Options" "stan_schools##options"}{...}
{viewerjumpto "Priors" "stan_schools##priors"}{...}
{viewerjumpto "Remarks" "stan_schools##remarks"}{...}
{viewerjumpto "Examples" "stan_schools##examples"}{...}
{title:Title}

{phang}
{bf:stan_schools} {hline 2} Fit a Bayesian hierarchical linear regression model using Stan (the "Schools" example from BUGS)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:stan_sc:hools}
{depvar}
[{varlist}]
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt model:file(filename)}}destination for .stan model file{p_end}
{synopt:{opt c:lusterid(varname)}}variable that defines the clusters (the "schools"){p_end}
{synopt:{opt rs:lopes(varlist)}}variables that have random slopes{p_end}
{synopt:{opt globals(globalslist)}}global macros that should be sent to Stan as scalars{p_end}
{synopt:{opt betap:riors(prior)}}prior shared among the fixed effect coefficients{p_end}
{synopt:{opt het:var(varnamelist)}}variable that explains heteroskedasticity{p_end}
{synopt:{opt thetap:rior(prior)}}prior for theta, the constant in the heteroskedasticity equation{p_end}
{synopt:{opt phip:rior(prior)}}prior for phi, the coefficient of {it:hetvar} in the heteroskedasticity equation{p_end}
{synopt:{opt sdep:rior(prior)}}prior for the error standard deviation when {it:hetvar} is not specified{p_end}
{synopt:{opt gammap:rior(prior)}}prior for gamma, the vector of means for the random effects (alphas){p_end}
{synopt:{opt sigmap:rior(prior)}}prior for Sigma, the covariance matrix for the random effects (alphas){p_end}
{synopt:{opt stano:pts(string)}}options to be passed to {it:{help stan:stan}}; you should not specify modelfile inside stanopts{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} and {cmd:fweight}s are not allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:stan_schools} fits a hierarchical (multilevel) linear regression model using Stan by populating the "Schools" example code, originally written for BUGS


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt modelfile} name (and path if desired) of the text file to contain the .stan model code; it is always replaced without warning

{phang}
{opt clusterid} variable that defines the clusters (the "schools"), which must be in consecutive intgers

{phang}
{opt rslopes} variables that have random slopes (alphas)

{phang}
{opt rslopes} global macros that should be sent to Stan as scalars

{phang}
{opt betapriors} Stan code fragment defining the prior shared among the fixed effect coefficients; default is "normal(0,100)"

{phang}
{opt hetvar} variable that explains heteroskedasticity by linearly predicting the log-variance of the observation-level errors

{phang}
{opt thetaprior} Stan code fragment defining the prior for theta, the constant in the heteroskedasticity equation; default is "normal(0,100)"

{phang}
{opt phiprior} Stan code fragment defining the prior for phi, the coefficient of {it:hetvar} in the heteroskedasticity equation; default is "normal(0,100)"

{phang}
{opt sdeprior} Stan code fragment defining the prior for the error standard deviation when {it:hetvar} is not specified; default is "normal(0,100)", which is truncated by the definition of sde in the parameter block so it is half-normal

{phang}
{opt gammaprior} Stan code fragment defining the prior for gamma, the vector of means for the random effects (alphas); default is a vector of zeros

{phang}
{opt sigmaprior} Stan code fragment defining the prior for Sigma, the covariance matrix for the random effects (alphas); default has 100 on the diagonal and zero off-diagonal

{phang}
{opt stanopts} options to be passed to {helpb stan}; you should not specify modelfile inside stanopts

{marker remarks}{...}
{title:Remarks}

{pstd}
The BUGS example, its translation onto Stan, and the various files used in the example are all at https://github.com/stan-dev/example-models/wiki/BUGS-Examples-Sorted-Alphabetically

{pstd}
For consistency with the BUGS example, stan_schools maintains the same Greek letters as in BUGS, despite them being unusual in places. We assume hetvar is in varlist.

{marker prior}{...}
{title:Priors in Stan code}

{pstd}
To fully understand the options available to you in the prior specification, refer to the Stan manual at http://mc-stan.org/documentation/

{pstd}
In brief, in each of the prior options, you can provide a string that will be inserted into the Stan code for the parameter(s) in question. For example, by typing {cmd:betapriors("normal(0,2)")}, that string will be inserted into a line in Stan for the beta parameters:

{pstd}
{cmd:beta ~ normal(0,2);}

{pstd} which will impose a normal prior for each beta, with mean 0 and standard deviation 2. You can also use distributions such as lognormal(), student_t(), cauchy(), uniform() or beta(). Remember that unknown values defined in the parameters block (which is the case for all the priors in stan_schools) cannot be discretely distributed; this is a limitation of Hamiltonian Monte Carlo and hence Stan (at present).

{marker examples}{...}
{title:Examples}

{phang}{cmd:. use "https://github.com/stan-dev/statastan/stan_examples/schools.dta", clear}{p_end}
{phang}{cmd:. qui tab school}{p_end}
{phang}{cmd:. global M=r(r)}{p_end}
{phang}{cmd:. qui count}{p_end}
{phang}{cmd:. global N=r(N)}{p_end}
{phang}{cmd:. stan_schools Y VR1 VR2 Gender LRT, rslopes(denom2 denom3 sgender) globals("N M") clusterid(school) 	stanopts(cmd("../cmdstan-2.6.2"))}{p_end}
