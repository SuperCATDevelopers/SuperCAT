# PSASettings.psd1
# Settings for PSScriptAnalyzer invocation.
@{
    Rules = @{
        PSUseCompatibleCommands = @{
            # Turns the rule on
            Enable = $true

            # Lists the PowerShell platforms we want to check compatibility with
            TargetProfiles = @(
                'win-8_x64_6.2.9200.0_3.0_x64_4.0.30319.42000_framework', # PS3.0_WindowsServer 2012
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework' #PS5.1_W10 1809 x64
            )
        }
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable = $true

            # Simply list the targeted versions of PowerShell here
            TargetVersions = @(
                '2.0',
                '3.0',
                '5.1',
                '6.2'
            )
        }
    }
}
