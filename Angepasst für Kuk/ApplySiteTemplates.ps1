$siteUrl = "https://xintranet.kepleruniklinikum.at/abteilungen/KSpace" #KUK
$listName = "Abteilungen"
$templateFilePath = $PSScriptRoot
$sharePointUrl = "https://xintranet.kepleruniklinikum.at/sites/" #KUK
$templateLibraryUrl = "/abteilungen/KSpace/Templates" #KUK

# Load SharePoint PowerShell snap-in if not already loaded
if ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

# Get the SharePoint web and list
$web = Get-SPWeb $siteUrl
$list = $web.Lists[$listName]

foreach ($item in $list.Items) {
    $siteCollectionUrl = $item["URL"]
     $templateName = $item["Select_x0020_Template"]
   
    $index = $templateName.IndexOf("#")
    if ($index -ne -1) {
        # Remove everything before and including '#'
        $templateName = $templateName.Substring($index + 1) + ".pnp"
    } else {
    }
    $updateTemplate = $item["Update_x0020_Template"]
    $itemId = $item["ID"]
    $commaIndex = $siteCollectionUrl.IndexOf(',')
    $substring = $siteCollectionUrl.Substring(0, $commaIndex)


    $siteExists = Get-SPSite -Identity $substring -ErrorAction SilentlyContinue

    if ($null -eq $siteExists) {
      Write-Host "No site collection found at: $substring" -ForegroundColor Red
    } else {
     if($updateTemplate -eq "yes"){
        try {
            # Download and apply the template
            Write-Host "$templateLibraryUrl/$templateName"
            Connect-PnPOnline -Url $siteUrl -CurrentCredentials
            Get-PnPFile -Url "$templateLibraryUrl/$templateName" -Path $templateFilePath -AsFile
            Disconnect-PnPOnline
            $templateFilePath2 = $templateFilePath + "\$templateName"
            Connect-PnPOnline -Url $substring -CurrentCredentials
            Get-PnPNavigationNode -Location QuickLaunch | Remove-PnPNavigationNode -Force
            $null = Apply-PnPProvisioningTemplate -Path $templateFilePath2
            Remove-Item -Path $templateFilePath2 -Force
            Disconnect-PnPOnline
            Connect-PnPOnline -Url $siteUrl -CurrentCredentials
            $null = Set-PnPListItem -List $listName -Identity $itemId -Values @{"Update_x0020_Template" = "update complete"}
            Disconnect-PnPOnline
            Write-Host "Template updated for $substring" -ForegroundColor Green
        }
        catch{
             Write-Host "An error occurred: $_.Exception.Message" -ForegroundColor Red
        }
     }
    }
}
$web.Dispose()
