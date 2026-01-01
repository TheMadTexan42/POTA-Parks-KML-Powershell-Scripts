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

# Function to generate prefix list from park data
function New-PrefixList {
    param(
        [string]$CsvPath,
        [string]$OutputPath
    )

    Write-Host "Generating prefix list from park data..."
    
    # Read the CSV and extract unique prefixes from the 'reference' column
    $prefixSet = @{}
    Import-Csv $CsvPath | ForEach-Object {
        $ref = $_.reference
        if ($ref.Length -ge 2) {
            $prefix = $ref.Substring(0,2)
            $prefixSet[$prefix] = $true
        }
    }

    # Sort and write to output file, each line commented
    $sortedPrefixes = $prefixSet.Keys | Sort-Object
    $header = @(
        "#  This is the list of valid POTA park prefixes",
        "#  Select a prefix to be included in the KML generation process",
        "#  by removing the # character at the beginning of the line",
        "#"
    )
    $lines = $header + ($sortedPrefixes | ForEach-Object { "#$_" })

    Set-Content -Path $OutputPath -Value $lines -Encoding UTF8
    Write-Host "Generated $OutputPath with $($sortedPrefixes.Count) unique prefixes."
}

# Function to initialize KML file with header
function Initialize-KMLFile {
    param([string]$FilePath)
    
    $header = @"
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
    <name>Parks.kml</name>
    <Style>
        <ListStyle>
            <listItemType>check</listItemType>
            <bgColor>00ffffff</bgColor>
            <maxSnippetLines>2</maxSnippetLines>
        </ListStyle>
    </Style>
    <Style id="s_ylw-pushpin_hl">
        <IconStyle>
            <scale>1.3</scale>
            <Icon>
                <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
            </Icon>
            <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
        </IconStyle>
        <LabelStyle>
            <scale>0</scale>
        </LabelStyle>
    </Style>
    <Style id="s_ylw-pushpin">
        <IconStyle>
            <scale>1.1</scale>
            <Icon>
                <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
            </Icon>
            <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
        </IconStyle>
        <LabelStyle>
            <scale>0</scale>
        </LabelStyle>
    </Style>
    <StyleMap id="m_ylw-pushpin">
        <Pair>
            <key>normal</key>
            <styleUrl>#s_ylw-pushpin</styleUrl>
        </Pair>
        <Pair>
            <key>highlight</key>
            <styleUrl>#s_ylw-pushpin_hl</styleUrl>
        </Pair>
    </StyleMap>
"@
    
    New-Item -ItemType "file" -Path $FilePath -Force | Out-Null
    Add-Content -Path $FilePath -Value $header
}

# Function to generate KML file for a specific prefix
function New-KMLFile {
    param(
        [string]$ParkListPath,
        [string]$OutputFile,
        [string]$Prefix
    )
    
    Write-Host "Generating KML for prefix: $Prefix"
    
    # Initialize the KML file
    Initialize-KMLFile -FilePath $OutputFile
    
    $sb = New-Object -TypeName "System.Text.StringBuilder"
    $counter = 0
    $lastParkName = ""
    
    # Process each park in the CSV
    Import-Csv $ParkListPath | ForEach-Object {
        $parkname = $_.reference
        $thisPrefix = $parkname -split "-"
        
        # Check if this park matches our prefix
        if ($thisPrefix[0] -eq $Prefix) {
            $counter++
            $lastParkName = $parkname
            
            # & is not a valid KML character so replace it with the word AND
            $description = $_.name -replace '&', 'and'
            
            # Append all of the KML for this park to the StringBuilder object
            [void] $sb.AppendLine('<Placemark>')
            [void] $sb.Append('<name>')
            [void] $sb.Append($parkname)
            [void] $sb.AppendLine('</name>')
            [void] $sb.Append('<description> <a href="https://pota.app/#/park/')
            [void] $sb.Append($parkname)
            [void] $sb.Append('">')
            [void] $sb.Append($description)
            [void] $sb.AppendLine('</a> </description>')
            [void] $sb.AppendLine('<styleUrl>#m_ylw-pushpin</styleUrl>')
            [void] $sb.AppendLine('<Point>')
            [void] $sb.Append('<coordinates>')
            [void] $sb.Append($_.longitude)
            [void] $sb.Append(',')
            [void] $sb.Append($_.latitude)
            [void] $sb.AppendLine(',0</coordinates>')
            [void] $sb.AppendLine('</Point>')
            [void] $sb.AppendLine('</Placemark>')
            
            # Every 500 parks, flush the string builder to the file
            if ($counter -ge 500) {
                Add-Content -Path $OutputFile -Value $sb.ToString()
                $sb.Length = 0
                $counter = 0
                Write-Host "  Processed park: $parkname"
            }
        }
    }
    
    # Finalize the KML file with closing tags
    [void] $sb.AppendLine('</Document>')
    [void] $sb.AppendLine('</kml>')
    
    # Write the last of the KML to the file
    Add-Content -Path $OutputFile -Value $sb.ToString()
    
    Write-Host "  Finished with $Prefix parks! Last park processed: $lastParkName"
}

# Check for park list file and prompt for download
if (Test-Path $parkList) {
    $fileCreated = (Get-Item $parkList).CreationTime
    Write-Host "Park list file found at '$parkList'"
    Write-Host "Last downloaded: $fileCreated"
    $response = Read-Host "Would you like to download the latest park list? (Y/N)"
} else {
    Write-Host "Park list file '$parkList' not found."
    $response = Read-Host "Would you like to download the latest park list now? (Y/N)"
}

if ($response -match '^(Y|y)') {
    Write-Host "Downloading latest park list from https://pota.app/all_parks_ext.csv ..."
    try {
        Invoke-WebRequest -Uri "https://pota.app/all_parks_ext.csv" -OutFile $parkList -UseBasicParsing
        Write-Host "Downloaded park list to $parkList"
    } catch {
        Write-Error "Failed to download park list: $_"
        exit 1
    }
} else {
    if (-not (Test-Path $parkList)) {
        Write-Host "Cannot proceed without park list file."
        exit 1
    }
    Write-Host "Using existing park list."
}

# Check for prefix list file
if (Test-Path $prefixList) {
    $fileModified = (Get-Item $prefixList).LastWriteTime
    Write-Host "Prefix list file found at '$prefixList'"
    Write-Host "Last modified: $fileModified"
    $response = Read-Host "Would you like to use the existing file or create a new one? (Use/Create)"
    if ($response -match '^(C|c)') {
        $createNewPrefix = $true
    } else {
        $createNewPrefix = $false
    }
} else {
    Write-Host "Prefix list file '$prefixList' not found."
    Write-Host "A new prefix list will be generated from the park data."
    $createNewPrefix = $true
}

if ($createNewPrefix) {
    New-PrefixList -CsvPath $parkList -OutputPath $prefixList
    Write-Host ""
    Write-Host "NEXT STEP:"
    Write-Host "  1. Open the file: $prefixList"
    Write-Host "  2. Remove the # character from the prefixes you want to process"
    Write-Host "  3. Save the file"
    Write-Host "  4. Run this script again"
    Write-Host ""
    exit 0
}

# Read prefix list and get uncommented lines
Write-Host ""
Write-Host "Reading prefix selections from $prefixList..."
$selectedPrefixes = @()
Get-Content $prefixList | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $selectedPrefixes += $line
    }
}

if ($selectedPrefixes.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No prefixes selected in $prefixList"
    Write-Host ""
    Write-Host "NEXT STEP:"
    Write-Host "  1. Open the file: $prefixList"
    Write-Host "  2. Remove the # character from the prefixes you want to process"
    Write-Host "  3. Save the file"
    Write-Host "  4. Run this script again"
    Write-Host ""
    exit 1
}

Write-Host "Found $($selectedPrefixes.Count) selected prefix(es): $($selectedPrefixes -join ', ')"
Write-Host ""

# Generate KML files for each selected prefix
foreach ($prefix in $selectedPrefixes) {
    $outfile = Join-Path $outputPath ($prefix.Trim() + "_parks.kml")
    New-KMLFile -ParkListPath $parkList -OutputFile $outfile -Prefix $prefix.Trim()
}

Write-Host ""
Write-Host "All KML files generated successfully!"

