# This script takes the CSV list of parks available from the Parks on the Air System
# and parses it into one or more KML files for use with Google Earth
#
# There are 3 files that usually all live in the same directory, and that directory must be
# allowed to execute PowerShell scripts (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.1)
# Parameters are provided so that you can change the location of all files if they are not in the script directory
# (but gee whizz man - just put the stuff all together so it works, OK?!?!?!?)
#
# To use the script you first select the park designator regions you want to output in the POTAPrefixList.txt file.
# This file contains one line per valid POTA park designator prefix.
#    ****  THEY ARE ALL COMMENTED OUT BY DEFAULT.  IF YOU CHANGE NOTHING - NO FILES WILL BE GENERATED ********
#
# To select a region for output, delete the pound (hashtag) # character at the beginning of the line for that prefix.  You can generate
# as many regions at a time as you want by uncommenting more than one line.
#
# Save the edited POTAPrefixList.txt file and then run the generation script using .\Generate_POTA_KMLs.ps1
# The script takes some time to run, but it will output a line of text for each park it processes so you will know it is still running.
#
#
# ****** For advanced users ******
# You can change the location of the POTAPrefixList.txt file or the path for the output file by passing the script the
# parameters -prefixList and -outputPath.
#
# Generate_POTA_KMLs.ps1 is just a batch script which calls CreateKML.ps1 repeatedly.
# You can call this script directly if you wish to combine multiple regions into one KML file, or change the filenames/paths
# Documentation for CreateKML.ps1 is in the comments in that file


#Declare the possible parameters for this script.  The defaults assume that everything is local
[CmdletBinding()]
param (  
    [Parameter()]
    [String]$prefixList = ".\POTAPrefixList.txt",

    [Parameter()]
    [String]$parkList = ".\all_parks_ext.csv",

    [Parameter()]
    [String]$outputPath = ".\"
)

#load the list of prefixes from the file (default is .\POTAPrefixList.txt)
$prefixes = Get-Content $prefixList
#Go through every line in the file
foreach ($line in $prefixes)
{
    #check for a comment character anywhere in the line, or a blank line.  If one is found, skip this line
    if ( ($line.contains("#")) -or ($line.Trim() -eq "") )
    {
        continue;
    }
    else 
    {
        #Generate the full path and filename for the parks starting with this prefix
        $outfile = $outputPath + $line.Trim() + "_parks.kml"

        #Call the script to parse the park list and output just this prefix
        #the defaults assume that everything is located in the script source directory
        #.\CreateKML.ps1 -outputFile $outfile -Prefixes $line -parkList $parkList
        $command = '.\CreateKML.ps1 -outputFile ' + $outfile + ' -Prefixes ' + $line + ' -parkList ' + $parkList
        Write-Host $command
        Start-Process 'powershell.exe' -ArgumentList $command
    }
}

Write-Host "All processes launched"
