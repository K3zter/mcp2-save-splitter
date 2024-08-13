
param(
	[Parameter(Position=0)]
	[string]$command="split",
    [Parameter()]
    [string]$basecard="blank.bin",
	[Parameter()]
    [string]$psu,
	[Parameter()]
    [string]$folder
 )


$myMcFolder = ".\mymc"
$psvConverterCmd = ".\psv-converter\psv-converter-win.exe"
$importFolder = ".\import"
$exportFolder = ".\export"
$tempFolder = ".\temp"
$cmd = "$($myMcFolder)\mymc.exe"
$psuNameMaxLength = 32
$gameIdRegex = 'S[A-Z]{3}-\d{5}'

Function Confirm-MyMcPresent {
	$fileExists = Test-Path $cmd
	if (!$fileExists) {
		Write-Output "ERROR: mymc.exe not dedected - please check the readme"
		exit
	}
}

Function Confirm-PsvConverterPresent {
	return Test-Path $psvConverterCmd
}

Function Confirm-MyMcVersion {
	$version = (& $cmd "--version" | Select-String -Pattern '2.6.g2').Matches.Value
	if($version -ne '2.6.g2')  {
		Write-Output "ERROR: Incorrect version of MyMc detected - please check the readme"
		exit
	}
}

Function Confirm-BaseCardExists {
	$fileExists = Test-Path (Join-Path ".\" $basecard)
	if (!$fileExists) {
		Write-Output "ERROR: Designated base card $basecard not detected"
		exit
	}
}

Function Confirm-PsuFileExists {
	if(!$psu) {
		Write-Output "ERROR: Please specify a save to add using -psu"
		exit
	}
	if(!($psu -Like "*.psu")) {
		Write-Output "ERROR: PSU file extension incorrect - ensure the file is a .psu file"
		exit
	}

	$fileExists = Test-Path (Join-Path ".\" $psu)
	if (!$fileExists) {
		Write-Output "ERROR: PSU file to add $psu not detected"
		exit
	}

}

Function Confirm-FolderToRemove {
	if(!$folder) {
		Write-Output "ERROR: Please specify a folder to remove using -folder"
		exit
	}
}

Function Confirm-FilesToImport {
	$saveFileCount = (Get-ChildItem -Path "$($importFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps','*.psv','*.mc2','*.ps2','*.bin') |  Measure-Object).Count
	if ($saveFileCount -eq 0) {
		Write-Output "No save files detected in import folder"
		exit
	}
}

Function Confirm-FilesInExport {
	$vmcFileCount = (Get-ChildItem -Path "$($exportFolder)\*" -Include ('*.mc2') -Recurse |  Measure-Object).Count
	if ($vmcFileCount -eq 0) {
		Write-Output "No VMC files detected in export folder"
		exit
	}
}

Function Move-Mc2sToTemp {
	$mcFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.mc2
	foreach($mcFile in $mcFiles) {
		Copy-Item  -Force -Path "$($importFolder)\$($mcFile.Name)" -Destination "$($tempFolder)\$($mcFile.BaseName).bin"
	}
}

Function Rename-ExportMc2sToBin {
	$mcFiles = Get-ChildItem -Path "$($exportFolder)\*" -Include *.mc2 -Recurse
	foreach($mcFile in $mcFiles) {
		Rename-Item -Force -Path "$($mcFile.Directory)\$($mcFile.Name)" -NewName "$($mcFile.BaseName).bin"
	}
}

Function Rename-ExportBinsToMc2 {
	$mcFiles = Get-ChildItem -Path "$($exportFolder)\*" -Include *.bin -Recurse
	foreach($mcFile in $mcFiles) {
		Rename-Item -Force -Path "$($mcFile.Directory)\$($mcFile.Name)" -NewName "$($mcFile.BaseName).mc2"
	}
}

Function Add-PsuToExportBins {
	$mcFiles = Get-ChildItem -Path "$($exportFolder)\*" -Include *.bin -Recurse
	foreach($mcFile in $mcFiles) {
		Write-Output("Adding PSU to $($mcFile.Name.Replace(".bin",".mc2"))...")
		$fullMcFilePath = "$($mcFile.Directory)\$($mcFile.Name)"
		$result = & $cmd $fullMcFilePath import $psu 2>&1
		$result = [string] $result
		if($result.indexOf("directory exists") -gt -1) {
			Write-Output("ERROR: $($mcFile.Name.Replace(".bin",".mc2")) already contains a folder with this name")
		}
		if($result.indexOf("out of space") -gt -1) {
			Write-Output("ERROR: $($mcFile.Name.Replace(".bin",".mc2")) - not enough space for file")
		}
	}
}

Function Remove-PsuFromExportBins {
	$mcFiles = Get-ChildItem -Path "$($exportFolder)\*" -Include *.bin -Recurse
	foreach($mcFile in $mcFiles) {
		Write-Output("Removing $folder dir from $($mcFile.Name.Replace(".bin",".mc2"))...")
		$fullMcFilePath = "$($mcFile.Directory)\$($mcFile.Name)"
		$result = & $cmd $fullMcFilePath delete $folder 2>&1
		$result = [string] $result
		if($result -and $result.indexOf("directory not found") -gt -1) {
			Write-Output("ERROR: $($mcFile.Name.Replace(".bin",".mc2")) does not have $folder folder")
		}
	}
}

Function Move-Ps2sToTemp {
	$mcFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.ps2
	foreach($mcFile in $mcFiles) {
		
		Copy-Item  -Force -Path (Join-Path $importFolder $mcFile.Name) -Destination  (Join-Path $tempFolder $mcFile.Name)
	}
}

Function Move-BinsToTemp {
	$binFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.bin
	foreach($binFile in $binFiles) {
		if (Test-Path -Path "$($tempFolder)\$($binFile.BaseName).bin") {
			$filesWithMatchingName = Get-ChildItem -Path "$($tempFolder)\$($binFile.BaseName)*" -Include *.bin
			$newName = "$($binFile.BaseName)-$($filesWithMatchingName.Count).bin"
			Copy-Item  -Force -Path "$($importFolder)\$($binFile.Name)" -Destination "$($tempFolder)\$($newName).bin"
		} else {
			Copy-Item  -Force -Path "$($importFolder)\$($binFile.Name)" -Destination "$($tempFolder)\$($binFile.BaseName).bin"
		}
	}
}

Function Move-SaveFilesToTemp {
	$saveFiles = Get-ChildItem -Path "$($importFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps')
	foreach($saveFile in $saveFiles) {
		Copy-Item  -Force -Path (Join-Path $importFolder $saveFile.Name) -Destination (Join-Path $tempFolder $saveFile.Name)
	}
}


Function Move-PsvsToTemp {
	$psvFiles = Get-ChildItem -Path (Join-Path $importFolder "\*") -Include *.psv
	foreach($psvFile in $psvFiles) {
		Copy-Item  -Force -Path (Join-Path $importFolder $psvFile.Name) -Destination (Join-Path $tempFolder $psvFile.Name)
	}
}


Function Convert-PsvsToPsus {
	$psvFiles = Get-ChildItem -Path (Join-Path $tempFolder "\*") -Include *.psv
	foreach($psvFile in $psvFiles) {
		& $psvConverterCmd (Join-Path $psvFile.Directory $psvFile.Name)
	}
}


Function Export-Psus($mcFile) {
	$prm = "$($tempFolder)\$($mcFile.Name)", "dir"
	$saveList = & $cmd $prm
	if($saveList.getType().Name -eq "String") {
		Write-Output "No saves found in $($mcFile.BaseName)"
		continue
	}
	$saves = New-Object Collections.Generic.List[String]
	for($i = 0; $i -lt $saveList.Length; $i = $i + 3) {
		if ($saveList[$i] -match $gameIdRegex) {
			$psuName = $saveList[$i].Substring(0, $psuNameMaxLength).Trim()
			if($psuName.Length) {
				$saves.Add($psuName)
			}
		}
	}
	
	if($saves.Length) {
		foreach($save in $saves) {
			$sanitizedFileName = $save.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$counter = 1
			Write-Output "Found $($save) in $($mcFile.BaseName)..."
			$fullMcFilePath = "$($tempFolder)\$($mcFile.Name)"
			if(Test-Path -Path "$($tempFolder)\$($sanitizedFileName).psu" -PathType Leaf) {
				while(Test-Path -Path "$($tempFolder)\$($sanitizedFileName)-$($counter).psu" -PathType Leaf) {
					$counter++
				}
				$prm = $fullMcFilePath, "export", "--directory=$tempFolder", "--output-file=$($sanitizedFileName)-$($counter).psu", $save
			}else{
				$prm = $fullMcFilePath, "export", "--directory=$tempFolder", "--output-file=$($sanitizedFileName).psu", $save
			}
			& $cmd $prm
		}
	}
	
}

Function Get-PsusFromBins {
	$binFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include *.bin

	foreach($binFile in $binFiles) {
		Write-Output ''
		Export-Psus $binFile
	}
}

Function Get-PsusFromPs2s {
	$ps2Files = Get-ChildItem -Path "$($tempFolder)\*" -Include *.ps2

	foreach($ps2File in $ps2Files) {
		Export-Psus $ps2File
	}
}

Function Get-PsuWithGameId($saveFile) {
	Copy-Item -Path (Join-Path ".\" $basecard) -Destination (Join-Path $tempFolder "tempCard.bin")
	$prm = $prm = (Join-Path $tempFolder "tempCard.bin"), "import", (Join-Path $tempFolder $($saveFile.Name))
	& $cmd $prm
	$newSaveFile = Get-ChildItem -Path (Join-Path $tempFolder "tempCard.bin")
	Export-Psus($newSaveFile)
	Remove-Item -Path (Join-Path $tempFolder "tempCard.bin")
}

Function Repair-SavesWithNoGameId {
	$saveFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps')
	foreach($saveFile in $saveFiles) {
		if(!($saveFile.BaseName -match $gameIdRegex)) {
			Get-PsuWithGameId($saveFile)
			Remove-Item -Path (Join-Path $saveFile.Directory $saveFile.Name)
		}
	}
}

Function New-CardIfNotExist {
	Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $gameId,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $channelNum
    )
	if (!(Test-Path -Path (Join-Path $exportFolder $gameId))) {
		New-Item -ItemType Directory -Force -Path (Join-Path $exportFolder $gameId)
	}

	if (!(Test-Path -Path (Join-Path $exportFolder $gameId | Join-Path -ChildPath "$($gameId)-$($channelNum).bin"))) {
		Copy-Item -Path (Join-Path ".\" $basecard) -Destination (Join-Path $exportFolder $gameId | Join-Path -ChildPath "$($gameId)-$($channelNum).bin")
	}
}

Function Import-FileToCard {
	Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $gameId,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $channelNum,
		 [Parameter(Mandatory=$true, Position=2)]
         $saveFile
    )
	$prm = ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin", "import", ".\$($tempFolder)\$($saveFile.Name)"
	$result = & $cmd $prm 2>&1
	$result = [string] $result
	if($result.indexOf("directory exists") -gt -1 -or $result.indexOf("out of space") -gt -1) {
		return $false
	} else {
		return $result
	}

}

Function New-Vmcs {
	$saveFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps')

	foreach($saveFile in $saveFiles) {
		$channelNum = 1
		if($saveFile.BaseName -match $gameIdRegex) {
			$gameId = $Matches.0
		} else {
			Write-Output "Could not find Game ID in $($saveFile.Name)"
			continue
		}

		New-CardIfNotExist $gameId $channelNum
		$result = Import-FileToCard $gameId $channelNum $saveFile
		if($result) {
			Write-Output $result
			continue
		}

		for ($nextChannel = 2; $nextChannel -lt 10; $nextChannel++) {
			if ($nextChannel -eq 9) {
				Write-Output "Too many saves for $($saveFile.BaseName), ignoring"
				continue
			} 
			New-CardIfNotExist $gameId $nextChannel
			$result = Import-FileToCard $gameId $nextChannel $saveFile
			if($result) {
				Write-Output $result
				break
			}
		}
	}

	$exportFiles = $saveFiles = Get-ChildItem -Recurse -Path "$($exportFolder)\*" -Include *.bin

	foreach($exportFile in $exportFiles) {
		Move-Item -Path "$($exportFile.Directory)\$($exportFile.Name)" -Destination "$($exportFile.Directory)\$($exportFile.BaseName).mc2" -Force
	}
}

Function New-TempDir {
	if (!(Test-Path -Path "$($tempFolder)")) {
		New-Item -ItemType Directory -Force -Path "$($tempFolder)"
	}
}

Function Clear-TempDir {
	Remove-Item -Force -Recurse -Path "$($tempFolder)"
}

Function Move-FilesToTempDir {
	Move-SaveFilesToTemp
	Move-Mc2sToTemp
	Move-Ps2sToTemp
	Move-BinsToTemp
}

Function Convert-PsvFiles {
	$psvFiles = Get-ChildItem -Path (Join-Path $importFolder "\*") -Include *.psv
	if($psvFiles.Length -gt 0 -and !(Confirm-PsvConverterPresent)) {
		Write-Output ".psv files ignored as psv-converter-win.exe not found - please check the readme"
		return
	}
	Move-PsvsToTemp
	Convert-PsvsToPsus
}

Function Get-Psus {
	Get-PsusFromBins
	Get-PsusFromPs2s
}

Confirm-MyMcPresent
Confirm-MyMcVersion

if($command -eq "split") {
	Confirm-BaseCardExists
	Confirm-FilesToImport
	New-TempDir 
	Move-FilesToTempDir
	Convert-PsvFiles
	Get-Psus
	Repair-SavesWithNoGameId
	New-Vmcs
	Clear-TempDir
}

if($command -eq "add") {
	Confirm-PsuFileExists
	Confirm-FilesInExport
	Rename-ExportMc2sToBin
	Add-PsuToExportBins
	Rename-ExportBinsToMc2
}

if($command -eq "remove") {
	Confirm-FolderToRemove
	Confirm-FilesInExport
	Rename-ExportMc2sToBin
	Remove-PsuFromExportBins
	Rename-ExportBinsToMc2
}

