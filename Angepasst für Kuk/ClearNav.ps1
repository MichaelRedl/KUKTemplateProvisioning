$siteUrl = "https://xintranet.kepleruniklinikum.at/sites/testmr5" 


Connect-PnPOnline -Url $siteUrl -CurrentCredentials

Get-PnPNavigationNode -Location QuickLaunch | Remove-PnPNavigationNode -Force



Disconnect-PnPOnline
