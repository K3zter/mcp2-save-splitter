$myMcFolder = ".\mymc"
$psvConverterCmd = ".\psv-converter\psv-converter-win.exe"
$importFolder = ".\import"
$exportFolder = ".\export"
$tempFolder = ".\temp"
$cmd = "$($myMcFolder)\mymc.exe"

Function Confirm-MyMcPresent {
	$fileExists = Test-Path $cmd
	if (!$fileExists) {
		echo "ERROR: mymc.exe not dedected - please check the readme"
		exit
	}
}

Function Confirm-PsvConverterPresent {
	return Test-Path $psvConverterCmd
}

Function Confirm-MyMcVersion {
	$version = (& $cmd "--version" | Select-String -Pattern '2.6.g2').Matches.Value
	if($version -ne '2.6.g2')  {
		echo "ERROR: Incorrect version of MyMc detected - please check the readme"
		exit
	}
}

Function Move-PsuFromRootDir {
	$psuFiles = Get-ChildItem -Path ".\*" -Include *.psu

	foreach($psuFile in $psuFiles) {
		if (Test-Path -Path ".\$($tempFolder)\$($psuFile.Name)") {
			$filesWithMatchingName = Get-ChildItem -Path ".\$($tempFolder)\$($psuFile.BaseName)*" -Include *.psu
			$newName = "$($psuFile.BaseName)-MCPCH-$($filesWithMatchingName.Count + 1).psu"
			Move-Item -Path ".\$($psuFile.Name)" -Destination ".\$($tempFolder)\$($newName)"
		} else {
			Move-Item -Path ".\$($psuFile.Name)"  -Destination ".\$($tempFolder)\$($psuFile.Name)"
		}
	}
}

Function Move-Mc2sToTemp {
	$mcFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.mc2
	foreach($mcFile in $mcFiles) {
		Copy-Item  -Force -Path "$($importFolder)\$($mcFile.Name)" -Destination "$($tempFolder)\$($mcFile.BaseName).bin"
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
		echo "No saves found in $($mcFile.BaseName)"
		continue
	}
	$saves = New-Object Collections.Generic.List[String]
	for($i = 0; $i -lt $saveList.Length; $i = $i + 3) {
		if ($saveList[$i] -match 'S[A-Z][A-Z][A-Z]-\d\d\d\d\d') {
			$endOfId = $saveList[$i].IndexOf(" ")
			$psuName = $saveList[$i].Substring(0,$endOfId).Trim()
			if($psuName.Length) {
				$saves.Add($psuName)
			}
		}
	}
	
	if($saves.Length) {
		foreach($save in $saves) {
			echo "Found $($save) in $($mcFile.BaseName)..."
			$prm = "$($tempFolder)\$($mcFile.Name)", "export", $save
			& $cmd $prm
		}
	}
	Move-PsuFromRootDir
}

Function Get-PsusFromBins {
	$binFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include *.bin

	foreach($binFile in $binFiles) {
		echo ''
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
	Copy-Item -Path ".\blank.bin" -Destination (Join-Path $tempFolder "tempCard.bin")
	$prm = $prm = (Join-Path $tempFolder "tempCard.bin"), "import", (Join-Path $tempFolder $($saveFile.Name))
	& $cmd $prm
	$newSaveFile = Get-ChildItem -Path (Join-Path $tempFolder "tempCard.bin")
	Export-Psus($newSaveFile)
	Remove-Item -Path (Join-Path $tempFolder "tempCard.bin")
}

Function Repair-SavesWithNoGameId {
	$saveFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps')
	foreach($saveFile in $saveFiles) {
		if(!($saveFile.BaseName -match 'S[A-Z][A-Z][A-Z]-\d\d\d\d\d')) {
			Get-PsuWithGameId($saveFile)
			Remove-Item -Path (Join-Path $saveFile.Directory $saveFile.Name)
		}
	}
}

Function New-Vmcs {
	$saveFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include ('*.psu','*.xps','*.max','*.cbs','*.sps')

	foreach($saveFile in $saveFiles) {
		$channelNum = 1
		if($saveFile.BaseName.indexOf("-MCPCH-") -gt -1) {
			$channelNum = ($saveFile.BaseName[-1..-1][0])
			$channelNum = [int]"$channelNum"
			if($channelNum -gt 8) {
				echo "Too many saves for $($saveFile.BaseName), ignoring"
				continue
			}
			echo "Multiple saves for $($saveFile.BaseName), creating card in channel $($channelNum)"
		}
		if($saveFile.BaseName -match 'S[A-Z][A-Z][A-Z]-\d\d\d\d\d') {
			$gameId = $Matches.0
		} else {
			echo "Could not find Game ID in $($saveFile.Name)"
			continue
		}
		if (!(Test-Path -Path ".\$($exportFolder)\$($gameId)\")) {
			New-Item -ItemType Directory -Force -Path ".\$($exportFolder)\$($gameId)\"
		}
		if (!(Test-Path -Path ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin")) {
			Copy-Item -Path ".\blank.bin" -Destination ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin"
		}
		
		$prm = $prm = ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin", "import", ".\$($tempFolder)\$($saveFile.Name)"
		& $cmd $prm
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
		echo ".psv files ignored as psv-converter-win.exe not found - please check the readme"
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
New-TempDir 
Move-FilesToTempDir
Convert-PsvFiles
Get-Psus
Repair-SavesWithNoGameId
New-Vmcs
Clear-TempDir