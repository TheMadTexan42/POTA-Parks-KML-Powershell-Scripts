# POTA-Parks-KML-Powershell-Scripts

# GenerateQSOmap.ps1 Usage Documentation
This PowerShell script generates a KML file from an ADIF file containing QSO (contact) records. The KML file can be imported into Google Earth or other mapping software to visualize QSO locations and, optionally, draw lines from your operating grid to each contact.

## Usage
You can run the script with or without command line parameters. If parameters are omitted, the script will prompt you for the required information.

### Command Line Parameters

- `-InputADIF <path>`  
  Path to the input ADIF file containing QSO records.

- `-OutputKML <path>`  
  Path where the generated KML file will be saved.

- `-OperatingGrid <grid>`  
  Your operating grid square (e.g., FN31).

- `-DrawLines`  
  (Switch) If specified, lines will be drawn from your operating grid to each QSO location.  The color of the lines is determined by the band.  There is table that specifies the color associated with each band at the top of the script.




#Generate_POTA_KMLs.ps1 - Used to generate a KML set of pins representing all POTA entites for specified prefixes.
Directions are in the comments in the file Generate_POTA_KMLs.ps1.  In a nutshell:

1.  Download the park CSV file from POTA and put it in the same directory as the scripts.
2.  Make sure you're setup with permissions to execute scripts from the directory where you put everything.
3.  Edit the file POTAPrefixList.txt.   Remove the number/pound/hashtag # charater from the beginning of the line for every region you want to put into a KML file.  This file
    contains only the prefixes valid for a park designator for POTA.  You can add lines to this file if it is out of date and there are new prefixes available.
4.  Run Generate_POTA_KMLs.ps1

These are Powershell scripts.  They process the CSV park list file provided by POTA (which you must figure out how to obtain yourself) into one or more KML files for use with Google Earth and other mapping programs.

No warranty of any kind is provided.  The only guarantee you'll get is that these will be hard to use - if they work at all.

These scripts do not connect to POTA directly in any way, an no modifications to do so are permitted.  
When you do connect to POTA, you do so under the obligation to follow all POTA rules and guidelines.  ANY abuse of the POTA system will not be tolerated and will result in your immediate loss of any and all rights to possess or use these scripts.
