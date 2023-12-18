# MCP2 Save Splitter
Simple powershell script for generating VMC .mc2 files for use with the Memcard Pro 2's GameID functionality.

This script relies on the application MyMC v2.6.g2 by gastroman. Download the file from [this page](https://sourceforge.net/projects/mymc-opl/files/) and place the contents of `mymc_2.6.g2.dist.7z` in the `mymc` folder. The file `mymc.exe` should be in the root of the folder.

In order to process `.psv` files, the tool PSV Save Converter is required. Download the Win64 build from [this page](https://github.com/bucanero/psv-save-converter/releases/tag/v1.2.1) and place `psv-converter-win.exe` in the `psv-converter` folder. 

Place any files you wish to use with the Memcard Pro 2 in the `import` folder. You can place OPL VMC files (.bin), PCSX2 VMC files (.ps2), MCP2 VMC files (.mc2) or save files in the  `.cbs`, `.max`, `.psu`, `.psv`, `.sps` and `.xps` formats.

Open a PowerShell window in the same folder as the script, and run the command:

    .\split.ps1

The script will populate the `export` folder with the newly generated files and folders for the Memcard Pro 2. Copy these folders into the "PS2" folder on the Memcard Pro 2 SD card.