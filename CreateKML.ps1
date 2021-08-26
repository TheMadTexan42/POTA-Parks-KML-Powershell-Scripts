# This is the script that parses the CSV file of parks from POTA and generates corresponding KML files.
#
# When called from Generate_POTA_KMLs.ps1, it is required that the downloaded CSV file be called
# all_parks_ext.csv (this is the default name when it is downloaded) and that it be located in the same directory as this script.
#
# There are parameters that allow you to control both the input and output file name/path, as well as what park
# designators are processed.  The outputFile and Prefix parameters are utilized by Generate_POTA_KMLs.ps1
#


[CmdletBinding()]
param (  

# parameter that specfies the name of the output KML file.  Generate_POTA_KMLs.ps1 passes this as {Designator}_parks.kml
# by default, output will go to the same directory as this script and be called POTA_Parks.kml
    [Parameter()]
    [String]$outputFile = ".\POTA_Parks.kml",

# List of park designators to process.  Generate_POTA_KMLs.ps1 will only pass one of these at a time, but a comma seperated list
# is valid, and will result in multiple park designators being put into the same KML file.
# For example; .\CreateKML.ps1 -Prefixes 'K','VE'   will result in one file with both US and Canada parks.
#
# The default is asterisk *, and results in all prefixes being processed.  **There is no other wild-card matching**.
# 'Z*' is NOT valid and will NOT generate a list of all parks starting with Z!
    [Parameter()]
    [String[]]$Prefixes = "*",

#The last parameter is the full path to the CSV list of parks.  The default is the name with which the file downloads from POTA
#and a directory that is the same as where this script resides.
    [Parameter()]
    [String]$inputFile = ".\all_parks_ext.csv"
)

function InitKML ($infile) 
#InitKML puts all of the KML header information into the output file.  It's really just one big ass string.
{
    Add-Content $infile "<?xml version=""1.0"" encoding=""UTF-8""?>
    <kml xmlns=""http://www.opengis.net/kml/2.2"" xmlns:gx=""http://www.google.com/kml/ext/2.2"" xmlns:kml=""http://www.opengis.net/kml/2.2"" xmlns:atom=""http://www.w3.org/2005/Atom"">
    <Document>
        <name>Parks.kml</name>
        <Style>
            <ListStyle>
                <listItemType>check</listItemType>
                <bgColor>00ffffff</bgColor>
                <maxSnippetLines>2</maxSnippetLines>
            </ListStyle>
        </Style>
        <Style id=""s_ylw-pushpin_hl"">
            <IconStyle>
                <scale>1.3</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
                </Icon>
                <hotSpot x=""20"" y=""2"" xunits=""pixels"" yunits=""pixels""/>
            </IconStyle>
            <LabelStyle>
                <scale>0</scale>
            </LabelStyle>
        </Style>
        <Style id=""s_ylw-pushpin"">
            <IconStyle>
                <scale>1.1</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
                </Icon>
                <hotSpot x=""20"" y=""2"" xunits=""pixels"" yunits=""pixels""/>
            </IconStyle>
            <LabelStyle>
                <scale>0</scale>
            </LabelStyle>
        </Style>
        <StyleMap id=""m_ylw-pushpin"">
            <Pair>
                <key>normal</key>
                <styleUrl>#s_ylw-pushpin</styleUrl>
            </Pair>
            <Pair>
                <key>highlight</key>
                <styleUrl>#s_ylw-pushpin_hl</styleUrl>
            </Pair>
        </StyleMap>
    "
}

#Start of the main script
#Check to see if the list of parks is readable
if (-not (Test-Path -Path $inputFile)) {
    #We couldn't find the list, so print a useful message and quit
    Write-Host "Could not find the CSV list of parks: " $inputFile
    exit
}

#Generate the output KML file.  The -Force attribute causes it to overwrite an existing file if found.
New-Item -ItemType "file" -Path "$outputFile" -Force
#Put all of the KML header info into the new file
InitKML($outputFile)

#Load and parse the CSV file of parks downloaded from POTA
Import-Csv $inputFile | ForEach-Object {
    #This is done for every park.
    #The Name of the park is in a column called "reference" in the CSV
    $parkname = $_.reference

    #Extract the prefix of the park designator by looking for the hypen character
    $thisPrefix = $parkname -split "-"

    #Check to see if the prefix is either an asterisk, or in the list of prefixes we specfied that we want
    if (($Prefixes -eq "*" ) -or ($Prefixes -contains $thisPrefix[0]))
    {
        #We want this park in the output, so generate the KML as a string
        $description = $_.name -replace '&', 'and'
        $kml = ""
        $kml = "<Placemark>`n"
        $kml += "<name>" + $parkname + "</name>`n"
        $kml += "<description>" +$description + " </description>`n"
        $kml += "<styleUrl>#m_ylw-pushpin</styleUrl>`n"
        $kml += "<Point>`n"
        $kml += "<coordinates>" + $_.longitude + "," + $_.latitude + ",0</coordinates>`n"
        $kml +="</Point>`n"
        $kml +="</Placemark>"

        #Add this park to the KML file
        Add-Content $outputFile $kml

        #Printe a status message to the console.  This script takes a while and seeing the park designators go by
        #lets the user know that it's still doing something productive.
        Write-Host "Processed park " $parkname
    }
}

#The list of parks is exhausted, so finalize the KML file with the required closing KML tags/footer
Add-Content $outputFile "</Document>"
Add-Content $outputFile "</kml>"

#Tell the world we're finished
Write-Host "Done!"


