
<a href="http://mc-stan.org">
<img src="https://raw.githubusercontent.com/stan-dev/logos/master/logo.png" width=200 alt="Stan Logo"/>
</a>

**StataStan** is the [Stata](http://www.stata.com) interface to [Stan](http://mc-stan.org).

Current status
---------
StataStan comprises a command **stan**, a command **windowsmonitor** (which is required for **stan** if you are using Windows), and a developing set of template functions under stan_examples that write your data to specific models, so that Stata users can become familiar with Stan without having to write the model code immediately. We invite all Stata users to test it out and give us feedback, either here on Github, or by email to Robert Grant at [robertstats@live.com](mailto:robertstats@live.com).

As of September 2015, there are some basic issues to fix and then the commands will be submitted to the Stata repository [SSC](https://ideas.repec.org/s/boc/bocode.html).

**stan** will fit a Stan model by Hamiltonian Monte Carlo. You can also ask for the posterior mode, which is found by optimization with the BFGS (or L-BFGS) algorithm. We intend to create more Stata commands, allowing CODA-style diagnostics and plotting after a model has been fitted and chains stored.

Getting Started
----------------
1. Download and install [CmdStan](http://mc-stan.org/cmdstan.html). Make sure you read the installation instructions and platform-specific appendix before installing. In particular, _if you are using 32-bit Windows_, you will need to add a file called 'local' to the 'make' folder before you run the *make* command, which should simply contain the text: *BIT=32*
1. Download the .ado and.sthlp files and save them in your Stata personal ado folder (click [here](http://www.stata.com/support/faqs/programming/personal-ado-directory/) if you don't know where this is)
1. Try out the different examples in the stan-example.do file, or under **help stan**
1. Try your own data and model. The Stan modelling manual is essential reading for this! Options are listed in detail under **help stan**.
1. You can pass your current data (the stuff you see when you type *browse* in Stata) into Stan, but also you can send matrices and global macros, by specifying their names or typing 'all' in the *matrices* and *globals* options. Unlike BUGS / JAGS, Stan just ignores data that your model doesn't use.

Testing
-----------------
StataStan has been tested with CmdStan 2.6.2 and 2.7.0, Stata versions from 11.2 to 14.0, and Stata flavors IC and SE. We have not added multicore capacity yet, but it is on the to-do list and is easy to do (see Stan manual).

We have run it successfully on Linux, Mac and Windows, but we would like to hear from you if it works (or not) with Windows 10 or versions of Stata older then 11.0.

Other notes
---------------
* Non-existent globals and matrices, and non-numeric globals, get quietly ignored
* Missing values are removed casewise by default (but you can change this)
* Users need to take care not to leave output file names as defaults if they have anything precious called output.csv or modes.csv etc. - these files will be overwritten

Licensing
---------
StataStan is licensed under BSD.