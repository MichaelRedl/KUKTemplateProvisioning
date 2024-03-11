# Define variables
$siteUrl = "https://xintranet.kepleruniklinikum.at"
$WebAppURL="https://xintranet.kepleruniklinikum.at"  
$siteCols = @()
#$appTitle = "multilevel-navigation-client-side-solution"
#$appTitle = "kuk-header-picture-client-side-solution"
#$appTitle = "kuk-quicklinks-webpart-client-side-solution"
#$appTitle = "kuk-events-webpart-client-side-solution"
$appTitle = "kuk-design-template-client-side-solution"

# Load SharePoint PowerShell snap-in if not already loaded
if ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

#Get list of site collections in a web application powershell  
$webApp = Get-SPWebApplication $WebAppURL
foreach ($site in $webApp.Sites) {
    $siteCols += $site.Url
    $site.Dispose()
}

foreach ($url in $siteCols) {
    Connect-PnPOnline -Url $url -CurrentCredentials
    $appInstance = Get-PnPApp -ErrorAction SilentlyContinue | Where-Object { $_.Title -eq $appTitle} 
    $appId = $appInstance.Id
    #Write-Host "The AppId is: $appId" -ForegroundColor Green
    if ($appInstance -ne $null -and $appInstance.InstalledVersion -ne $appInstance.AvailableVersion) {
        #Update-PnPApp -Identity [AppId] -Scope Site
      #  if($url -eq "https://xintranet.kepleruniklinikum.at/abteilungen/kprkomm" ) {
            #Write-Host "Multilevel Navigation found at site collection with url: " $url -ForegroundColor Green
            Update-PnPApp -Identity $appId -Scope Tenant
            Write-Host "App with Title $appTitle updated successfully for site collection with url: $url"  -ForegroundColor Green
      #  }
    }
    Disconnect-PnPOnline
}

