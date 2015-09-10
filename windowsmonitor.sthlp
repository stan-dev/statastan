{smcl}
{* *! version 1.0  10sep2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "stan" "help stan"}{...}
{viewerjumpto "Syntax" "windowsmonitor##syntax"}{...}
{viewerjumpto "Description" "windowsmonitor##description"}{...}
{viewerjumpto "Options" "windowsmonitor##options"}{...}
{viewerjumpto "Remarks" "windowsmonitor##remarks"}{...}
{viewerjumpto "Examples" "windowsmonitor##examples"}{...}
{title:Title}

{phang}
{bf:windowsmonitor} {hline 2} Send a {cmd:winexec} command to a Windows operating system and display the output in the Stata results window in (almost) real time


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:windowsmonitor}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt command(string)}}the Windows command{p_end}
{synopt:{opt winlog:file(filename)}}text file that will act as a temporary log of Windows output{p_end}
{synopt:{opt waitsecs(integer)}}how long to wait for output before giving up{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by}, {cmd:if}, {cmd:in} and {cmd:fweight}s are not allowed (nor are they relevant).


{marker description}{...}
{title:Description}

{pstd}
Windows unfortunately does not stream the outputs from command-line activity (technically, the stdout and stderr streams) in such a way that they can appear inside Stata. When running a {cmd:winexec} command, Stata waits for the process launched by the command to terminate before proceeding, and only then will all the output appear inside Stata. If the command is time-consuming (such as calling CmdStan, which was the inspiration for this), not seeing progress can cause worry, or a waste of time, or undetected problems. {cmd:windowsmonitor} is a work-around for this problem, which pipes the output to a text file, checks that file every 2 seconds and displays anything new in it.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt command} the Windows command, which will be invisibly augmented with the details to pipe output to winlogfile

{phang}
{opt winlogfile} file (and path, if desired) to store the output in; by default a Stata tempfile will be used, so there is nothing to be gained from specifying a tempfile macro here

{phang}
{opt waitsecs} number of seconds to wait for the first output before giving up


{marker remarks}{...}
{title:Remarks}

{pstd}
The winlogfile will contain a line:

{cmd:Finished!}

{pstd}
once the command finishes, and it is this line that will signal to {cmd:windowsmonitor} to hand control back to Stata. If your Windows command will write "Finished!" to the screen for some reason, that will cause early handing back (or some other problem).

{pstd}
It is possible that there may be some contention for access to the winlogfile, although despite serious use on different project, computers and Windows versions, it has never happened yet.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. windowsmonitor, command("ping 127.0.0.1 -n 30")} {p_end}
{phang}{cmd:. winexec ping 127.0.0.1 -n 30}{p_end}
