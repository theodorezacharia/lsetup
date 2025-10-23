<#
Author: Theodore Zacharia
V0.1 - 19/07/2022 - Initial Release of Windows PowerShell version, from V0.2 Bourne shell version
V0.2 - 16/06/2023 - Change top level structure in cfg file to an array form

Execute instructions in the json config file
Config files are in order of preference: Machine name specific, o/s specific, default.

MANDATORY: This script uses the excellent 'jq' utility,
        which MUST be available for the script to work

WINDOWS SPECIFIC:
You might need to do the following in an Admin Powershell script:
    Set-ExecutionPolicy Unrestricted
    or to avoid prompts each time you try to run
    Set-ExecutionPolicy Bypass -Scope CurrentUser
#>

<# Globals #>
$LSETUPCFG='lsetup.cfg'    # the default lsetup config file
$MNTFILTR=""
$FORCEIT=0
$TRACE=0
$TRUNSTEPS='lsetup.tmp.tmp'
$FINDCONFIGFILE=1
$LSETUPCFGFORCE=""
$POSARGSTART=0

<# Mainline #>
$TRACE=0
$i2=0

if ($TRACE -gt 0 ) { write-host "There are a total of $($args.count) arguments" }

for ( $i = 0; $i -lt $args.count; $i++ ) {
    if ($TRACE -gt 0 ) { write-host "Argument $i is $($args[$i])" }

    if ( $args[$i] -eq '-t' ) {
        write-host "setting -t NOTE -T is same in PowerShell"
        $TRACE=1
        $i2=$i2+1
    }
    elseif ( $args[$i] -eq '-c' ) {
        $i1=$i+1
        write-host "setting -c with $($args[$i1])"
        $LSETUPCFGFORCE=$($args[$i1])
        $i=$i+1
        $i2=$i2+1
    }
    elseif ( $args[$i] -eq '-f' ) {
        $FORCEIT=1
        $i2=$i2+1
    }
    elseif ( $args[$i] -eq '-d' ) {
        $FINDCONFIGFILE=0
        $i2=$i2+1
    }
    else
    {
        if ( $POSARGSTART -eq 0 ) { $POSARGSTART=$i2; }
    }

    # if not one of the above must be a positional one, so set here
}

if ($TRACE -gt 0) {
    write-host "trace is on ($trace)"
    write-host "Starting at $(get-date -Format F)"
}



if ( $args.count -eq 0)
{
    write-host "see option -h for help"
    exit 1
}


# find which config file to use
if ( $FINDCONFIGFILE -eq 1 )
{
    if ( "$LSETUPCFGFORCE" -ne "" )
    {
        $LSETUPCFG=$LSETUPCFGFORCE
    }
    else
    {
        # Look for Linux/Windows/Mac etc
        $CMPOS="$env:os"
        $CHKLSETUP="lsetup.${CMPOS}.cfg"
        if ( Test-Path "$CHKLSETUP" )
        {
            $LSETUPCFG=$CHKLSETUP
        }

        # Look for a machine name specific file
        $CMPNM="$env:computername"
        write-host "on $CMPNM"
        $CHKLSETUP="lsetup.${CMPNM}.cfg"
        if ( Test-Path "$CHKLSETUP" )
        {
            $LSETUPCFG=$CHKLSETUP
        }
    }
}

if ( $TRACE -gt 0 ) { write-host "using LSETUPCFG=$LSETUPCFG" }

# not sure how to get/shift arguments in the official way, so implemented equiv of OPTIND with shift

$MYARG1=$args[$POSARGSTART]
$MYARG2=$args[$POSARGSTART+1]

if ( $TRACE -gt 0 ) { write-host "MYARG1=${MYARG1} , MYARG2=${MYARG2}" }


# handle 1 parameter, 2 linked (requires type in the cfg) or 2 where 2nd is just data (type is empty in this case in the cfg)
if ( "$MYARG2" -ne "" )
{
    # if TWO parameters provided, need to handle ones where 2nd param may be something to pass into script
    # this is the case if the type in config is EMPTY
    jq --arg myjarg1 "$MYARG1" --arg myjarg2 "$MYARG2" ' .[] | select ( .service == $myjarg1 ) | select ( .type == $myjarg2 ) ' $LSETUPCFG | Tee-Object -Variable TRUN > Out-Null
    if ( $TRACE -gt 0 ) { write-host "Steps: $TRUN" }

    if ( "$TRUN" -eq "" )
    {
        jq --arg myjarg1 "$MYARG1" ' .[] | select ( .service == $myjarg1 ) | select ( .type == \"\" ) ' $LSETUPCFG | Tee-Object -Variable TRUN > Out-Null
    }
}
else
{
    # if ONE parameter passed, need to only select ones with no type
    jq --arg myjarg1 "$MYARG1" ' .[] | select ( .service == $myjarg1 )  | select ( .type == \"\" ) ' $LSETUPCFG | Tee-Object -Variable TRUN > Out-Null
}

if ( $TRACE -gt 1 ) { write-host "Steps: $TRUN" }
echo "$TRUN" | jq -r ' .steps[] ' > $TRUNSTEPS

if ( $TRACE -gt 1 ) { cat $TRUNSTEPS }


ForEach ($ASTEP in Get-Content $TRUNSTEPS)
{
    if ( $TRACE -gt 0 ) { write-host "running: $ASTEP" }
    # force to get input from terminal
    Invoke-Expression $ASTEP
}

rm $TRUNSTEPS
rm Out-Null