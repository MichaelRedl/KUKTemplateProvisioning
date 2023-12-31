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
    $newSiteTitle = $item["Title"]
    $newUrlSiteName = $item["UrlSiteName"]
    $newSiteUrl = $sharePointUrl + $newUrlSiteName
    $newSiteAdmin = $item["SiteAdmin"]
    $templateName = $item["Template"]

    $siteExists = Get-SPSite -Identity $newSiteUrl -ErrorAction SilentlyContinue

    if ($null -eq $siteExists) {
        try {
            # Create the new site collection using a default template
            $newSite = New-SPSite -Url $newSiteUrl -OwnerAlias $newSiteAdmin -Name $newSiteTitle -Template "SITEPAGEPUBLISHING#0" -ErrorAction Stop

            # Connect to the admin site collection
            Connect-PnPOnline -Url $siteUrl -CurrentCredentials

            # Download the template
            Get-PnPFile -Url "$templateLibraryUrl/$templateName" -Path $templateFilePath -AsFile
            $templateFilePath = $templateFilePath + "\$templateName"

            # Create Link DML and Link DMS
            $itemId = $item["ID"] | Out-String
            $linkDmlUrl = "https://dml.kepleruniklinikum.at/sites/" + $newUrlSiteName
            $linkDmlDesc = "https://dml.kepleruniklinikum.at/sites/"  + $newUrlSiteName
            $linkDmsUrl = "https://dms.kepleruniklinikum.ad/dms/dokumentationen"  + $newUrlSiteName
            $linkDmsDesc = "https://dms.kepleruniklinikum.ad/dms/dokumentationen"  + $newUrlSiteName
            
            # Update the list item
            $null = Set-PnPListItem -List $listName -Identity $itemId -Values @{"Link_x0020_DML" = $linkDmlUrl; "Link_x0020_DMS" = $linkDmsUrl; "Site_x0020_Collection_x0020_URL" = $newSiteUrl}
            Disconnect-PnPOnline

            # Apply the template
            Connect-PnPOnline -Url $newSiteUrl -CurrentCredentials
            $null = Apply-PnPProvisioningTemplate -Path $templateFilePath
            Remove-Item -Path $templateFilePath -Force

            Write-Host "Site collection created and template applied at $newSiteUrl" -ForegroundColor Green
        } catch {
            Write-Host "An error occurred: $_.Exception.Message" -ForegroundColor Red
        }
    } else {
        Write-Host "Site collection already exists at $newSiteUrl" -ForegroundColor Yellow
    }
}
$web.Dispose()
