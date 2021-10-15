Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'SuperCAT files are in the correct location' {
			$currentDir = [string](Get-Location)
			$currentDir + "\setup-powershell.ps1" | Should -Exist
			$currentDir + "\DISA" | Should -Exist
			$currentDir + "\AV" | Should -Exist
			$currentDir + "\Export\export-offline-eventlogs.ps1" | Should -Exist
			$currentDir + "\Export\export-offline-registry.ps1" | Should -Exist
			$currentDir + "\Tool\SuperCAT.ps1" | Should -Exist
		}
	}
}

