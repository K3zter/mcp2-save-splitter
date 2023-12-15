$myMcFolder = ".\mymc"
$importFolder = ".\import"
$exportFolder = ".\export"
$tempFolder = ".\temp"
$cmd = "$($myMcFolder)\mymc.exe"


Function Collect-Psu {
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

Function Rename-Mc2s {
	$mcFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.mc2
	foreach($mcFile in $mcFiles) {
		Copy-Item  -Force -Path "$($importFolder)\$($mcFile.Name)" -Destination "$($tempFolder)\$($mcFile.BaseName).bin"
	}
}

Function Move-Bins {
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

Function Move-Psus {
	$psuFiles = Get-ChildItem -Path "$($importFolder)\*" -Include *.psu
	foreach($psuFile in $psuFiles) {
		Copy-Item  -Force -Path "$($importFolder)\$($psuFile.Name)" -Destination "$($tempFolder)\$($psuFile.Name)"
	}
}

Function Recover-Saves {
	$binFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include *.bin

	foreach($binFile in $binFiles) {
		$prm = "$($tempFolder)\$($binFile.Name)", "dir"
		$saveList = & $cmd $prm
		if($saveList.getType().Name -eq "String") {
			echo "No saves found in $($binFile.BaseName)"
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
				echo "Found $($save) in $($binFile.BaseName)..."
				$prm = "$($tempFolder)\$($binFile.Name)", "export", $save
				& $cmd $prm
			}
		}
		Collect-Psu
	}
}

Function Generate-NewSaves {
	$psuFiles = Get-ChildItem -Path "$($tempFolder)\*" -Include *.psu

	foreach($psuFile in $psuFiles) {
		$channelNum = 1
		if($psuFile.BaseName.indexOf("-MCPCH-") -gt -1) {
			$channelNum = ($psuFile.BaseName[-1..-1][0])
			$channelNum = [int]"$channelNum"
			if($channelNum -gt 8) {
				echo "Too many saves for $($psuFile.BaseName), ignoring"
				continue
			}
			echo "Multiple saves for $($psuFile.BaseName), creating card in channel $($channelNum)"
		}
		if($psuFile.BaseName -match 'S[A-Z][A-Z][A-Z]-\d\d\d\d\d') {
			$gameId = $Matches.0
		} else {
			echo "Could not find Game ID in $($psuFile.Name)"
			continue
		}
		if (!(Test-Path -Path ".\$($exportFolder)\$($gameId)\")) {
			New-Item -ItemType Directory -Force -Path ".\$($exportFolder)\$($gameId)\"
		}
		if (!(Test-Path -Path ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin")) {
			Copy-Item -Path ".\blank.bin" -Destination ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin"
		}
		
		$prm = $prm = ".\$($exportFolder)\$($gameId)\$($gameId)-$($channelNum).bin", "import", ".\$($tempFolder)\$($psuFile.Name)"
		& $cmd $prm
	}

	$exportFiles = $psuFiles = Get-ChildItem -Recurse -Path "$($exportFolder)\*" -Include *.bin

	foreach($exportFile in $exportFiles) {
		Move-Item -Path "$($exportFile.Directory)\$($exportFile.Name)" -Destination "$($exportFile.Directory)\$($exportFile.BaseName).mc2" -Force
	}
}

if (!(Test-Path -Path "$($tempFolder)")) {
	New-Item -ItemType Directory -Force -Path "$($tempFolder)"
}
 
Move-Psus
Rename-Mc2s
Move-Bins
Recover-Saves
Generate-NewSaves

Remove-Item -Force -Recurse -Path "$($tempFolder)"