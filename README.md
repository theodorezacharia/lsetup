# lsetup
Local Setup - Setup your workday/homeday machine by starting apps you regularly need, no need for all that clicking


Each day there are a number of repetetive tasks to do when I start my machine up, like starting the VPN, mounting drives, starting the same set of programs every day.

I got bored pressing the same buttons over and over again, so wrote a shell script to start up the apps and apply settings as requried for work and or home.

The lsetup.sh utility takes a json config file which allows you to define the instructions to run as part of a group, so for example running ./lsetup.sh work apps will start up all your work apps as required, in the current workspace. I typically switch to another workspace and run ./lsetup.sh home apps to start my home applications.


I work on Linux so the initial version was Bourne shell based, but some collegues liked it but worked on Windows, so I also developed a PowerShell version for them.

Below are colourised versions of the files (main links) and the actual files themselves (see the download links).   


## Local Setup (Bourne Posix/Linux/Unix) version - lsetup script, supporting scripts and example configuration files
* [lsetup.sh - The main script](src/lsetup.sh)
* [lsetup.cfg - The instruction configuration file](src/lsetup.cfg)
* [lsetup.CerberusM19.cfg - A machine specific instruction configuration file](src/lsetup.CerberusM19.cfg)

## Supporting Scripts
* [mlan.lsetup.sh - script to mount network drives](src/mlan.lsetup.sh)
* [mounts.lsetup.conf - drive mount points file for mlan](src/mounts.lsetup.conf)

## Windows PowerShell version
* [lsetup.ps1 - The main PowerShell version of the script](src/lsetup.ps1)
* [lsetup.Windows_NT.cfg - A Windows 10/11 specific example instruction configuration file](src/lsetup.Windows_NT.cfg)

## Additional Linux Configuration
* [Mate Terminal configuration file](src/mateterm.lsetup.conf)
* [An alternate Mate Terminal configuration file](src/mateterm.lsetup.conf)
* [Terminator configuration file ( to ~/.config/terminator/config)](src/terminator.config)

## Configuration Info

The important part is the configuration of the *lsetup.cfg* file, take a look, I have given the actual file I use which does things like starting all my work and/or home apps with a single call, saves doing all that clicking each morning.

## Additional External Info

* Linux (and Windows) Terminal [configuration](https://towardsdatascience.com/how-to-get-an-amazing-terminal-91619a0beeb7)
