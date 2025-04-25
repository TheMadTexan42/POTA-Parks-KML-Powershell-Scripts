# This script generates a KML file from an ADIF file containing QSO records. Usable for importing into Google Earth or other mapping software.
# You can specify the ADIF input file, KML output file, operating grid, and line drawing option as command line parameters.
# If parameters are not specified, the script will prompt for them interactively.

param(
    [string]$InputADIF,
    [string]$OutputKML,
    [string]$OperatingGrid,
    [switch]$DrawLines
)

# Color table for US amateur bands
$bandColors = @{
    "160M" = "ff0000"; # Red
    "80M"  = "ff8000"; # Orange
    "40M"  = "ffff00"; # Yellow
    "30M"  = "80ff00"; # Light Green
    "20M"  = "00ff00"; # Green
    "17M"  = "00ff80"; # Teal
    "15M"  = "00ffff"; # Aqua
    "12M"  = "0080ff"; # Light Blue
    "10M"  = "0000ff"; # Blue
    "6M"   = "8000ff"; # Purple
    "2M"   = "ff00ff"; # Magenta
    "1.25M"= "ff0080"; # Pink
    "70cm" = "000000"; # Black
}

function Convert-MaidenheadToLatLon {
    param (
        [string]$grid
    )
    
    if ($grid.Length -lt 4 -or ($grid.Length -ne 4 -and $grid.Length -ne 6 -and $grid.Length -ne 8)) {
        throw "Grid square must be either 4, 6, or 8 characters long (e.g., FN31, FN31pr, or FN31pr45)."
    }

    # Extract grid components for basic calculation
    $A = [char]$grid[0]
    $B = [char]$grid[1]
    $C = [char]$grid[2]
    $D = [char]$grid[3]

    # Convert to longitude
    $lon = (([int][char]::ToUpper($A) - [char]'A') * 20) + ([int][char]$C * 2) - 180

    # Convert to latitude
    $lat = (([int][char]::ToUpper($B) - [char]'A') * 10) + ([int][char]$D) - 90

    # Check for sub-squares (5th and 6th characters)
    if ($grid.Length -ge 6) {
        $E = [char]$grid[4]
        $F = [char]$grid[5]

        $lon += (([int][char]::ToLower($E) - [char]'a') * (2.0 / 24))
        $lat += (([int][char]::ToLower($F) - [char]'a') * (1.0 / 24))
    }

    # Check for extended precision (7th and 8th characters)
    if ($grid.Length -eq 8) {
        $G = [char]$grid[6]
        $H = [char]$grid[7]

        $lon += ([int][char]$G * (2.0 / 240))
        $lat += ([int][char]$H * (1.0 / 240))
    }

    return @{
        Latitude = [math]::Round($lat, 3)
        Longitude = [math]::Round($lon, 3)
    }
}

function Generate-KMLHeader {
    return @"
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
"@
}

function Generate-KMLFooter {
    return @"
</kml>
"@
}

function Generate-PlacemarkTag {
    param (
        [string]$name,
        [double]$latitude,
        [double]$longitude
    )

    return @"
  <Placemark>
    <name>$name</name>
    <Point>
      <coordinates>$longitude,$latitude,0</coordinates>
    </Point>
  </Placemark>
"@
}

function Generate-LineTag {
    param (
        [string]$name,
        [double]$startLat,
        [double]$startLon,
        [double]$endLat,
        [double]$endLon,
        [string]$color
    )

    return @"
  <Placemark>
    <name>Line to $name</name>
    <Style>
      <LineStyle>
        <color>ff$color</color>
        <width>2</width>
      </LineStyle>
    </Style>
    <LineString>
      <coordinates>
        $startLon,$startLat,0
        $endLon,$endLat,0
      </coordinates>
    </LineString>
  </Placemark>
"@
}

function Process-ADIFFile {
    param (
        [string]$filePath,
        [string]$outputKMLPath,
        [string]$operatingGrid,
        [bool]$drawLines
    )

    # Check if the output file already exists
    if (Test-Path -Path $outputKMLPath) {
        Write-Host "The file '$outputKMLPath' already exists. Do you want to overwrite it? (Yes/No)"
        $response = Read-Host "Enter your choice"

        if ($response -notmatch "^(Yes|Y)$") {
            Write-Host "Exiting the script. The file was not overwritten."
            exit
        }
    }

    $kmlHeader = Generate-KMLHeader
    $kmlFooter = Generate-KMLFooter
    $placemarks = ""
    $lines = ""

    # Add the operating grid square as a reference placemark
    try {
        $opCoordinates = Convert-MaidenheadToLatLon -grid $operatingGrid
        $placemarks += Generate-PlacemarkTag -name "Operating Grid: $operatingGrid" -latitude $opCoordinates.Latitude -longitude $opCoordinates.Longitude
    } catch {
        Write-Warning "Failed to process operating grid square '$operatingGrid': $_"
    }

    # Read ADIF file contents
    $adifContent = Get-Content -Path $filePath -Raw

    # Split into QSO records using <EOR>
    $records = $adifContent -split "<EOR>"

    foreach ($record in $records) {
        # Extract the CALLSIGN, GRIDSQUARE, and BAND fields using regular expressions
        $callSign = ""
        $grid = ""
        $band = ""

        if ($record -match "<CALL:([0-9]+)>([A-Za-z0-9/]+)") {
            $callSign = $Matches[2]
        }

        if ($record -match "<GRIDSQUARE:([0-9]+)>([A-Za-z0-9]+)") {
            $grid = $Matches[2]
        }

        if ($record -match "<BAND:([0-9]+)>([A-Za-z0-9]+)") {
            $band = $Matches[2]
        }

        if ($callSign -ne "" -and $grid -ne "" -and $band -ne "") {
            try {
                $coordinates = Convert-MaidenheadToLatLon -grid $grid
                $placemarks += Generate-PlacemarkTag -name "$callSign" -latitude $coordinates.Latitude -longitude $coordinates.Longitude
                if ($drawLines) {
                    $color = $bandColors[$band] # Lookup the color for the band
                    if (-not $color) {
                        $color = "ffffff" # Default to white if the band is unknown
                    }
                    $lines += Generate-LineTag -name "$callSign" -startLat $opCoordinates.Latitude -startLon $opCoordinates.Longitude -endLat $coordinates.Latitude -endLon $coordinates.Longitude -color $color
                }
            } catch {
                Write-Warning "Failed to process grid square '$grid' for callsign '$callSign': $_"
            }
        }
    }

    # Combine the header, placemarks, lines (if enabled), and footer
    $kmlContent = $kmlHeader + $placemarks
    if ($drawLines) {
        $kmlContent += $lines
    }
    $kmlContent += $kmlFooter

    # Save the KML file
    Set-Content -Path $outputKMLPath -Value $kmlContent -Encoding UTF8
    Write-Host "KML file generated: $outputKMLPath"
}

# Set defaults and prompt only if not provided as parameters
$currentDirectory = (Get-Location).Path
$defaultADIFPath = Join-Path -Path $currentDirectory -ChildPath "QSOs.adif"
$defaultKMLPath = Join-Path -Path $currentDirectory -ChildPath "qsomap.kml"

if (-not $InputADIF) {
    Write-Host "Enter the path to the ADIF file (default: $defaultADIFPath):"
    $adifFilePath = Read-Host "ADIF file path"
    if ([string]::IsNullOrWhiteSpace($adifFilePath)) {
        $adifFilePath = $defaultADIFPath
    }
} else {
    $adifFilePath = $InputADIF
}

if (-not $OutputKML) {
    Write-Host "Enter the path to save the KML file (default: $defaultKMLPath):"
    $outputKMLPath = Read-Host "KML file path"
    if ([string]::IsNullOrWhiteSpace($outputKMLPath)) {
        $outputKMLPath = $defaultKMLPath
    }
} else {
    $outputKMLPath = $OutputKML
}

if (-not $OperatingGrid) {
    Write-Host "Enter your Operating Grid Square (e.g., FN31):"
    $operatingGrid = Read-Host "Operating Grid Square"
} else {
    $operatingGrid = $OperatingGrid
}

if (-not $PSBoundParameters.ContainsKey('DrawLines')) {
    Write-Host "Do you want to include lines connecting the Operating Grid to QSO records? (Yes/No)"
    $drawLinesResponse = Read-Host "Enable Line Drawing"
    $drawLines = $drawLinesResponse -match "^(Yes|Y)$"
} else {
    $drawLines = $DrawLines.IsPresent
}

# Process the ADIF file
Process-ADIFFile -filePath $adifFilePath -outputKMLPath $outputKMLPath -operatingGrid $operatingGrid -drawLines $drawLines