$siteUrl = "https://dev19.dccs-demo.at/sites/sitecoladmin" #DCCS
$listName = "Site Collections"
$templateFilePath = $PSScriptRoot
$sharePointUrl = "https://dev19.dccs-demo.at/sites/" #DCCS
$templateLibraryUrl = "/sites/sitecoladmin/Templates" #DCCS

# Load SharePoint PowerShell snap-in if not already loaded
if ((Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

# Get the SharePoint web and list
$web = Get-SPWeb $siteUrl
$list = $web.Lists[$listName]

foreach ($item in $list.Items) {
    $siteCollectionUrl = $item["Site_x0020_Collection_x0020_URL"]
    $templateName = $item["Template"]
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
            $templateFilePath = $templateFilePath + "\$templateName"
            Connect-PnPOnline -Url $substring -CurrentCredentials
            $null = Apply-PnPProvisioningTemplate -Path $templateFilePath
            Remove-Item -Path $templateFilePath -Force
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
