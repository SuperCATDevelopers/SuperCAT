Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'setup_powershell.ps1 exists' {
			$currentDir = [string](Get-Location)
			$currentDir + "\setup_powershell.ps1" | Should -Exist
		}
		It 'current directory' {
			$currentDir = Get-Location
			$currentDir | Should -Be "D:\a\SuperCAT\SuperCAT"
		}
	}
}
