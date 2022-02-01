# This test validates the folder structure of SuperCAT to ensure that all the essential files will be in the correct location on disk.
Describe 'SuperCAT Structure' {
	Context 'File Structure' {
		It 'DISA Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\Scripts\SCAP" | Should -Exist
		}
		It 'AV Directory Check' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\Scripts\McAfeeAV_v2" | Should -Exist
			$currentDir + "\Tool\Scripts\McAfeeAV_v2\w32" | Should -Exist
			$currentDir + "\Tool\Scripts\McAfeeAV_v2\w64" | Should -Exist
			$currentDir + "\Tool\Scripts\McAfeeAV_v2\DAT" | Should -Exist
		}
		It 'QuickLookTool checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\Scripts\QuickLookTools\FilterEventLogs.ps1" | Should -Exist
			$currentDir + "\Tool\Scripts\QuickLookTools\export-offline-registry.ps1" | Should -Exist
		}
		It 'SuperCAT main file checks' {
			$currentDir = [string](Get-Location)
			$currentDir + "\Tool\SuperCAT.ps1" | Should -Exist
			$currentDir + "\Tool\Modules\Support.psm1" | Should -Exist
		}
	}
}

