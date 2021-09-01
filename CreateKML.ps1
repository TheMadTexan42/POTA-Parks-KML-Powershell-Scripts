# This is the script that parses the CSV file of parks from POTA and generates corresponding KML files.
##
# There are parameters that allow you to control both the input and output file name/path, as well as what park
# designators are processed. 
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
    [String]$parkList = ".\all_parks_ext.csv"
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
if (-not (Test-Path -Path $parkList)) {
    #We couldn't find the list, so print a useful message and quit
    Write-Host "Could not find the CSV list of parks: " $parkList
    exit
}

#Generate the output KML file.  The -Force attribute causes it to overwrite an existing file if found.
New-Item -ItemType "file" -Path "$outputFile" -Force
#Put all of the KML header info into the new file
InitKML($outputFile)

$sb = New-Object -TypeName "System.Text.StringBuilder";

#Load and parse the CSV file of parks downloaded from POTA
#The counter lets us flush the string builder periodically.
$counter = 0;
Import-Csv $parkList | ForEach-Object {
    #This is done for every park.
    #The Name of the park is in a column called "reference" in the CSV
    $parkname = $_.reference

    #Extract the prefix of the park designator by looking for the hypen character
    $thisPrefix = $parkname -split "-"

    #Check to see if the prefix is either an asterisk, or in the list of prefixes we specfied that we want
    if (($Prefixes -eq "*" ) -or ($Prefixes -contains $thisPrefix[0]))
    {
        #We'll process this park so increment the counter
        $counter += 1;

        #& is not a valid KML character so replace it with the word AND
        $description = $_.name -replace '&', 'and'

        #Append all of the KML for this park to the StringBuilder object
        [void] $sb.AppendLine('<Placemark>');
        [void] $sb.Append('<name>'); 
        [void] $sb.Append($parkname);
        [void] $sb.AppendLine('</name>');
        [void] $sb.Append('<description> <a href="https://pota.app/#/park/');
        [void] $sb.Append($parkname);
        [void] $sb.Append('">');        
        [void] $sb.Append($description);
        [void] $sb.AppendLine('</a> </description>');
        [void] $sb.AppendLine('<styleUrl>#m_ylw-pushpin</styleUrl>');
        [void] $sb.AppendLine('<Point>');
        [void] $sb.Append('<coordinates>');
        [void] $sb.Append($_.longitude);
        [void] $sb.Append(',');
        [void] $sb.Append($_.latitude);
        [void] $sb.AppendLine(',0</coordinates>');
        [void] $sb.AppendLine('</Point>');
        [void] $sb.AppendLine('</Placemark>');

        #Every 500 parks, flush the string builder to the file
        if($counter -ge 500)
        {
            Add-Content -Path $outputFile -Value $sb.ToString();
            $sb.Length = 0;
            $counter = 0;

            #Printe a status message to the console.  This script takes a while and seeing the park designators go by
            #lets the user know that it's still doing something productive.
            Write-Host "Processed park: " $parkname
        }
    }
}


#The list of parks is exhausted, so finalize the KML file with the required closing KML tags/footer
[void] $sb.AppendLine('</Document>');
[void] $sb.AppendLine('</kml>');

#$write the last of the KML to the file
Add-Content $outputFile $sb.ToString();

#Write the final status message
Write-Host "Finished with " $thisPrefix[0] " parks!  Last park processed was: " $parkname
