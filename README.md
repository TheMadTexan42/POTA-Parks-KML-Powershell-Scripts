# CSV_to_KML.ps1 - POTA Parks KML Converter

A unified PowerShell script that converts Parks on the Air (POTA) CSV data into KML files for use with Google Earth and other mapping applications.

## Overview

This script streamlines the process of creating KML files from POTA park data by combining park data download, prefix selection, and KML generation into a single interactive workflow.

## Features

- **Interactive park data management**: Automatically prompts to download the latest park list from POTA
- **Automatic prefix list generation**: Creates a list of all valid park prefixes from the CSV data
- **Selective region processing**: Generate KML files for only the regions you're interested in
- **Efficient processing**: Uses StringBuilder for optimal performance when processing large datasets
- **Progress tracking**: Displays progress messages during KML generation

## Requirements

- PowerShell 5.1 or later
- Internet connection (for downloading park data)
- Execution policy set to allow script execution ([see Microsoft docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy))

## Quick Start

1. **Run the script**:
   ```powershell
   .\CSV_to_KML.ps1
   ```

2. **Follow the interactive prompts**:
   - The script will check for the park data file (`all_parks_ext.csv`)
   - If found, you can choose to download a fresh copy or use the existing file
   - If not found, you'll be prompted to download it

3. **Select prefixes**:
   - The script checks for `POTAPrefixList.txt`
   - If it doesn't exist, it will be automatically generated
   - If it exists, you can choose to use it or create a new one

4. **Edit the prefix list**:
   - Open `POTAPrefixList.txt` in any text editor
   - Remove the `#` character from the prefixes you want to process
   - Save the file

   Example:
   ```
   # Before (no parks will be generated):
   #K
   #VE
   
   # After (will generate K_parks.kml and VE_parks.kml):
   K
   VE
   ```

5. **Run the script again**:
   ```powershell
   .\CSV_to_KML.ps1
   ```
   
   The script will now generate KML files for your selected prefixes.

## Workflow

### Step 1: Park Data File Check
- **File exists**: Shows when it was last downloaded and offers to download a fresh copy
- **File missing**: Prompts to download from https://pota.app/all_parks_ext.csv

### Step 2: Prefix List Check
- **File exists**: Shows last modified date and offers to use existing or create new
- **File missing**: Automatically generates a new prefix list with all prefixes commented out

### Step 3: Prefix Selection Validation
- Reads `POTAPrefixList.txt` and checks for uncommented lines
- If no prefixes are selected, displays instructions and exits
- If prefixes are found, proceeds to KML generation

### Step 4: KML Generation
- Generates one KML file per selected prefix
- Files are named `{PREFIX}_parks.kml` (e.g., `K_parks.kml`, `VE_parks.kml`)
- Displays progress messages every 500 parks
- Shows completion status for each prefix

## Parameters

The script accepts optional parameters for advanced users:

```powershell
.\CSV_to_KML.ps1 [-prefixList <path>] [-parkList <path>] [-outputPath <path>]
```

### Parameters:
- **`-prefixList`**: Path to the prefix list file (default: `.\POTAPrefixList.txt`)
- **`-parkList`**: Path to the park CSV file (default: `.\all_parks_ext.csv`)
- **`-outputPath`**: Directory where KML files will be saved (default: `.\`)

### Example:
```powershell
.\CSV_to_KML.ps1 -outputPath "C:\KML_Files\"
```

## Output Files

Generated KML files will contain:
- Park reference (e.g., K-0001)
- Park name with clickable link to POTA website
- Geographic coordinates (latitude/longitude)
- Standard KML styling for Google Earth compatibility

## Common Park Prefixes

Some common POTA prefixes include:
- **K** - United States
- **VE** - Canada
- **ZL** - New Zealand
- **VK** - Australia
- **G** - England
- **DL** - Germany

See the generated `POTAPrefixList.txt` file for a complete list of available prefixes.

## Troubleshooting

### Script won't run
Ensure your PowerShell execution policy allows script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Download fails
- Check your internet connection
- Verify the POTA website is accessible: https://pota.app/all_parks_ext.csv
- Try downloading the file manually and placing it in the script directory

### No KML files generated
- Verify you've uncommented at least one prefix in `POTAPrefixList.txt`
- Ensure the prefix exists in the park data (check the file for valid prefixes)
- Confirm the CSV file contains valid park data

### KML file won't open in Google Earth
- Ensure the file has a `.kml` extension
- Verify the file isn't corrupted (should be a text file with XML content)
- Try opening with a text editor to check the format

## File Descriptions

- **CSV_to_KML.ps1**: Main script file
- **all_parks_ext.csv**: Park data downloaded from POTA (auto-generated)
- **POTAPrefixList.txt**: List of park prefixes with selection markers (auto-generated)
- **{PREFIX}_parks.kml**: Generated KML files for each selected prefix

## Notes

- The script uses the file creation date to track when the park list was downloaded
- Park data is filtered by the two-character prefix at the beginning of the park reference
- The script processes all parks in the CSV for each selected prefix
- Generated KML files will overwrite existing files with the same name

## License

This script is provided as-is for use with Parks on the Air data. When accessing POTA resources, you must follow all POTA rules and guidelines.
