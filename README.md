# MCP2 Save Splitter
Simple PowerShell script for generating and modifying VMC .mc2 files for use with the Memcard Pro 2's GameID functionality.

This script relies on the application MyMC v2.6.g2 by gastroman. Download the file from [this page](https://sourceforge.net/projects/mymc-opl/files/) and place the contents of `mymc_2.6.g2.dist.7z` in the `mymc` folder. The file `mymc.exe` should be in the root of the folder.

In order to run this script, you will need to update your PowerShell execution policy to run unsigned scripts, this can be done by running PowerShell as administrator and running the following command:

    Set-ExecutionPolicy unrestricted

If you wish to reverse this change you can run this command in PowerShell as administrator:

    Set-ExecutionPolicy restricted

The script currently performs three separate functions:
 - **Save Splitting**: Take a collection of PS2 virtual memory card (VMC) files and individual save files from the `import` folder and generate separate MCP2 compatible VMC files in the `export` folder
 - **Import PSU to existing VMCs**: Import a specified `.psu` file to every single `.mc2` file (MCP2 VMC) in the `existing_cards` folder
 - **Remove folder from existing VMCs**: Remove a given named folder from every single `.mc2` file (MCP2 VMC) in the `existing_cards` folder

The latter two functions are intended for the purposes of adding an OPL IGR command to every VMC - but it is quite flexible and it may be useful for other things. I don't know what! Instructions for each of these functions are outlined below.

# IMPORTANT: PLEASE ENSURE ALL YOUR SAVE FILES ARE BACKED UP BEFORE USING THIS TOOL TO PREVENT RISK OF SAVE FILE LOSS OR CORRUPTION

## Save Splitting
In order to process `.psv` files, the tool PSV Save Converter is required. Download the Win64 build from [this page](https://github.com/bucanero/psv-save-converter/releases/tag/v1.2.1) and place `psv-converter-win.exe` in the `psv-converter` folder. 

Place any files you wish to use with the Memcard Pro 2 in the `import` folder. You can place OPL VMC files (.bin), PCSX2 VMC files (.ps2), MCP2 VMC files (.mc2) or save files in the  `.cbs`, `.max`, `.psu`, `.psv`, `.sps` and `.xps` formats.

Open a PowerShell window in the same folder as the script, and run the command:

    .\mcp2tools.ps1 split

The script will populate the `export` folder with the newly generated files and folders for the Memcard Pro 2. Copy these folders into the "PS2" folder on the Memcard Pro 2 SD card.

If you want to use a template card as a basis for all generated cards, for example one populated with an `igr` folder - you can add a `-basecard` parameter specifying a template card, for example:

    .\mcp2tools.ps1 split -basecard igr.mc2

A template card called `igr.mc2` has been included in the repo. It contains the file `igr/igr.elf`. In order to use this with OPL, set your `igr path` to `mc0:/igr/igr.elf` (use mc0 for slot 1, mc1 for slot 2).

## Import PSU to existing VMCs
This can be used to import a given PSU file to every `.mc2` file in the `existing_cards` folder. Begin by populating the `existing_cards` folder with the contents of your `PS2` folder from the MCP2 SD card.

PSU files can be created using wLaunchELF via copy -> psuPaste on a memory card directory. A PSU file called `igr.psu` has been included, it represents the file `igr/igr.elf`.

Open a PowerShell window in the same folder as the script, and run the command (for example):

    .\mcp2tools.ps1 add -psu igr.psu

Once the process is complete, copy the contents of the `existing_cards` folder back into the `PS2` folder of your MCP2 SD card - overwriting the existing files. **Ensure your MCP2 files are backed up prior to this step.**

## Remove folder from existing VMCs
This can be used to remove a given named directory `.mc2` file in the `existing_cards` folder. Begin by populating the `existing_cards` folder with the contents of your `PS2` folder from the MCP2 SD card.

The main purpose of this command is to remove directories you have added previously via this script, for example if they are no longer needed or to update the files.

`igr` is the name of the folder added if you use the included files - if you import your own files you will need to know the name of the directory you created.

Open a PowerShell window in the same folder as the script, and run the command (for example):

    .\mcp2tools.ps1 remove -folder igr

Once the process is complete, copy the contents of the `existing_cards` folder back into the `PS2` folder of your MCP2 SD card - overwriting the existing files. **Ensure your MCP2 files are backed up prior to this step.**