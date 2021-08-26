# This script takes the CSV list of parks available on the POTA website;
#          https://pota.app/all_parks_ext.csv
# and parses it into one or more KML files for use with Google Earth
#
# There are 3 files that must all live in the same directory, and that directory must be
# allowed to execute PowerShell scripts (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.1)
#
# To use the script you must first select the park designator regions you want to output in the POTAPrefixList.txt file.
# This file contains one line per valid POTA park designator prefix.
#    ****  THEY ARE ALL COMMENTED OUT BY DEFAULT.  IF YOU CHANGE NOTHING - NO FILES WILL BE GENERATED ********
#
# To select a region for output, delete the semi-colon ; character at the beginning of the line for that prefix.  You can generate
# as many regions at a time as you want by uncommenting more than one line.
#
# Save the edited POTAPrefixList.txt file and then run the generation script using .\Generate_POTA_KMLs.ps1
# The script takes some time to run, but it will output a line of text for each park it processes so you will know it is still running.
#
#
#
# ****** For advanced users ******
# You can change the location of the POTAPrefixList.txt file or the path for the output file by passing the script the
# parameters -inputFile and -outputPath.
#
# Generate_POTA_KMLs.ps1 is just a batch script which calls CreateKML.ps1 repeatedly.
# You can call this script directly if you wish to combine multiple regions into one KML file, or change the filenames/paths
# Documentation for CreateKML.ps1 is in the comments in that file



#Declare the possible parameters for this script.  The defaults assume that everything is local
[CmdletBinding()]
param (  
    [Parameter()]
    [String]$inputFile = ".\POTAPrefixList.txt",

    [Parameter()]
    [String]$outputPath = ".\"
)

#load the list of prefixes from the file (default is .\POTAPrefixList.txt)
$prefixes = Get-Content $inputFile
#Go through every line in the file
foreach ($line in $prefixes)
{
    #check for a semi-colon anywhere in the line.  If one is found, skip this line
    if (-not ($line.contains(";")))
    {
        #Generate the full path and filename for the parks starting with this prefix
        $outfile = $outputPath + $line + "_parks.kml"

        #Call the script to parse the park list and output just this prefix
        #NOTE - there is no option here to change the path to .\all_parks_ext.csv 
        #the list of parks must be in the same directory as CreateKML.ps1
        .\CreateKML.ps1 -outputFile $outfile -Prefixes $line
    }
}
