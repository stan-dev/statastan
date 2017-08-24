
<a href="http://mc-stan.org">
<img src="https://raw.githubusercontent.com/stan-dev/logos/master/logo.png" width=200 alt="Stan Logo"/>
</a>

**StataStan** is the [Stata](http://www.stata.com) interface to [Stan](http://mc-stan.org).

Current status
---------
StataStan comprises a command **stan**, a command **windowsmonitor** (which is required for **stan** if you are using Windows), and a developing set of template functions under stan_examples that write your data to specific models, so that Stata users can become familiar with Stan without having to write the model code immediately. We invite all Stata users to test it out and give us feedback, either here on Github, or by email to Robert Grant at [robert@bayescamp.com](mailto:robert@bayescamp.com).

Most recent changes - version 1.2.3, SSC release 3 March 2017:
* Incorporates changes to Stan output variables from CmdStan (reads in columns after energy__)
* Bug in the load option fixed

Version 1.2.1 & 1.2.2, SSC release 16 Sep 2016, and hotfix 1 Oct 2016
* various bug fixes too tedious to list - see the commits for stan.ado for details

Version 1.2:
* You can run multiple chains with the **chains** option.
* The **chainfile** option can be abbreviated to chainf but no shorter. This avoids confusion with the new **chains** option.
* Whatever name you give in **outputfile** will now have ".csv" appended on the end. If you run more than 1 chain, you will get consecutively numbered files like output1.csv, output2.csv, etc. **On Mac and Linux machines, the name should contain no spaces. We will try to work around this in future versions.**
* To avoid clashes with existing files, both the working directory and the CmdStan directory get checked for pre-existing output*.csv files.
* The StataStan and CmdStan version numbers are displayed at the beginning of output. The CmdStan number will be used in future versions for back compatibility.

Version 1.1, SSC release 29 Feb 2016:
* print has been replaced with stansummary
* all files are cleaned up from the CmdStan directory and appear in the working directory instead
* added a 'keepfiles' option - without this, wmbatch (in Windows), winlogfile (in Windows), outputfile, .hpp will be deleted. The executable, datafile and chainsfile are retained no matter what.

**stan** will fit a Stan model by Hamiltonian Monte Carlo. You can also ask for the posterior mode, which is found by optimization with the BFGS (or L-BFGS) algorithm. We intend to create more Stata commands:
* allowing CODA-style diagnostics and plotting after a model has been fitted and chains stored,
* fitting specific models given variables, matrices, globals -- in the style of the R package rstanarm,
* and a test script.

Getting Started
----------------
1. Download and install [CmdStan](http://mc-stan.org/users/interfaces/cmdstan.html). Make sure you read the installation instructions and platform-specific appendix before installing. In particular, _if you are using 32-bit Windows_, you will need to add a file called 'local' to the 'make' folder before you run the *make* command, which should simply contain the text: *BIT=32*
1. Don't forget to specify the number of CPU cores when you build CmdStan, so you can take advantage of parallel chains and the faster model-fitting that can deliver.
1. Download the .ado and.sthlp files and save them in your Stata personal ado folder (click [here](http://www.stata.com/support/faqs/programming/personal-ado-directory/) if you don't know where this is)
1. Try out the different examples in the stan-example.do file, or under **help stan**
1. Try your own data and model. The Stan modelling manual is essential reading for this! Start small and build up. Options are listed in detail under **help stan**.
1. You can pass your current data (the stuff you see when you type *browse* in Stata) into Stan, but also you can send matrices and global macros, by specifying their names or typing 'all' in the *matrices* and *globals* options. Unlike BUGS / JAGS, Stan just ignores data that your model doesn't use.

Testing
-----------------
StataStan has been tested with CmdStan 2.9 to 2.14, Stata versions from 11.2 to 14.2, and Stata flavors IC and SE. We have run it successfully on Linux, Mac and Windows, but we would like to hear from you if it works (or not) with Windows 10 or versions of Stata older than 11.

Other notes
---------------
* We find that specifying the CmdStan directory with a tilde in Mac OSX causes problems, and a complete path is advisable
* On Mac and Linux, it is a really good idea to have the working directory and cmdstan directory paths without spaces. For parallel chains, this is essential at present (v1.2.2)
* Non-existent globals and matrices, and non-numeric globals, get quietly ignored
* Missing values are removed casewise by default (but you can change this)
* Users need to take care not to leave output file names as defaults if they have anything precious called output.csv or modes.csv etc. - these files will be overwritten

Makers
---------
StataStan was mostly made by @robertgrant with valuable contributions from @sergiocorreia, @felixleungsc, @syclik, @danielcfurr, Charles Opondo and @bob-carpenter, plus constant encouragement and strategic direction from @gelman. We also learnt a lot from John Thompson's Stata commands for BUGS. We welcome ideas and contributions and will credit you here. StataStan was initially partly funded (grant holders Andrew Gelman and Sophia Rabe-Hesketh) by the Institute of Education Sciences, USA.

Licensing
---------
StataStan is licensed under BSD.
