Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'Setup file check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\setup-powershell.ps1" | Should -Exist
		}
		It 'DISA Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\DISA" | Should -Exist
		}
		It 'AV Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\AV" | Should -Exist
			$currentDir + "\AV\w32" | Should -Exist
			$currentDir + "\AV\w64" | Should -Exist
			$currentDir + "\AV\DAT" | Should -Exist
		}
		It 'QuickLookTool checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\QuickLookTools\export-offline-eventlogs.ps1" | Should -Exist
			$currentDir + "\Tool\QuickLookTools\export-offline-registry.ps1" | Should -Exist
		}
		It 'SuperCAT main file checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\SuperCAT.ps1" | Should -Exist
			$currentDir + "\Tool\config.json" | Should -Exist
		}
	}
}

