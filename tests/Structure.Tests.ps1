Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'setup_powershell.ps1 exists' {
			"/setup_powershell.ps1" | Should -Exist
		}
	}
}
