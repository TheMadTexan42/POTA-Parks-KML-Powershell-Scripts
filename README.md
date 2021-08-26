# POTA-Parks-KML-Powershell-Scripts

Directions are in the comments in the file Generate_POTA_KMLs.ps1.  In a nutshell:

1.  Download the park CSV file from POTA and put it in the same directory as the scripts.
2.  Make sure you're setup with permissions to execute scripts from the directory where you put everything.
3.  Edit the file POTAPrefixList.txt.   Remove the semi-colon ; charater from the beginning of the line for every region you want to put into a KML file
4.  Run Generate_POTA_KMLs.ps1

These are Powershell scripts.  They process the CSV park list file provided by POTA (which you must figure out how to obtain yourself) into one or more KML files for use with Google Earth and other mapping programs.

No warranty of any kind is provided.  The only guarantee you'll get is that these will be hard to use - if they work at all.

These scripts do not connect to POTA directly in any way, an no modifications to do so are permitted.  
When you do connect to POTA, you do so under the obligation to follow all POTA rules and guidelines.  ANY abuse of the POTA system will not be tolerated and will result
in your immediate loss to all of these resources!
