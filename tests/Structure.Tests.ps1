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
		}
		It 'Export EventLogs check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Export\export-offline-eventlogs.ps1" | Should -Exist
		}
		It 'Export Registry Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Export\export-offline-registry.ps1" | Should -Exist
		}
		It 'SuperCAT main file check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\SuperCAT.ps1" | Should -Exist
		}
	}
}

