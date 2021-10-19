# This test validates the folder structure of SuperCAT to ensure that all the essential files will be in the correct location on disk.
Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'Setup file check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\setup-powershell.ps1" | Should -Exist
		}
		It 'DISA Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\DISA" | Should -Exist
		}
		It 'AV Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\AV" | Should -Exist
			$currentDir + "\Tool\AV\w32" | Should -Exist
			$currentDir + "\Tool\AV\w64" | Should -Exist
			$currentDir + "\Tool\AV\DAT" | Should -Exist
		}
		It 'QuickLookTool checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\QuickLookTools\FilterEventLogs.ps1" | Should -Exist
			$currentDir + "\Tool\QuickLookTools\export-offline-registry.ps1" | Should -Exist
		}
		It 'SuperCAT main file checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\SuperCAT.ps1" | Should -Exist
			$currentDir + "\Tool\config.json" | Should -Exist
		}
	}
}

