
# Generate POTAPrefixList.txt from all_parks_ext.csv
$csvPath = Join-Path -Path (Get-Location) -ChildPath "all_parks_ext.csv"
$outputPath = Join-Path -Path (Get-Location) -ChildPath "POTAPrefixList.txt"


if (-not (Test-Path $csvPath)) {
	Write-Host "CSV file not found: $csvPath"
	$response = Read-Host "Would you like to download the latest park list from https://pota.app/all_parks_ext.csv? (Y/N)"
	if ($response -match '^(Y|y)') {
		try {
			Invoke-WebRequest -Uri "https://pota.app/all_parks_ext.csv" -OutFile $csvPath -UseBasicParsing
			Write-Host "Downloaded park list to $csvPath"
		} catch {
			Write-Error "Failed to download park list: $_"
			exit 1
		}
	} else {
		Write-Host "Aborted. CSV file is required."
		exit 1
	}
}

# Read the CSV, skip the header, extract the prefix from the 'reference' column
$prefixSet = @{}
Import-Csv $csvPath | ForEach-Object {
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
	"#  by removing the # character at the begining of the line",
	"#"
)
$lines = $header + ($sortedPrefixes | ForEach-Object { "#$_" })

# Prompt before overwriting if file exists
if (Test-Path $outputPath) {
	$response = Read-Host "File $outputPath already exists. Overwrite? (Y/N)"
	if ($response -notmatch '^(Y|y)') {
		Write-Host "Aborted. File not overwritten."
		exit 0
	}
}

Set-Content -Path $outputPath -Value $lines -Encoding UTF8
Write-Host "Generated $outputPath with $($sortedPrefixes.Count) unique prefixes."
