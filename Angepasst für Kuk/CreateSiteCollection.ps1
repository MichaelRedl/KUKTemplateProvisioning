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
    $newSiteTitle = $item["Title"]
    $newUrlSiteName = $item["UrlSiteName"]
    $newSiteUrl = $sharePointUrl + $newUrlSiteName
    $newSiteAdmin = $item["SiteAdmin"]
    $templateName = $item["Select_x0020_Template"]
   
    $index = $templateName.IndexOf("#")
    if ($index -ne -1) {
        # Remove everything before and including '#'
        $templateName = $templateName.Substring($index + 1) + ".pnp"
    } else {
    }


    $siteExists = Get-SPSite -Identity $newSiteUrl -ErrorAction SilentlyContinue

    if ($null -eq $siteExists -and $newSiteTitle -ne "Template") {
        try {
            # Create the new site collection using a default template
            $newSite = New-SPSite -Url $newSiteUrl -OwnerAlias $newSiteAdmin -Name $newSiteTitle -Template "STS#3" -ErrorAction Stop

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
            $null = Set-PnPListItem -List $listName -Identity $itemId -Values @{"Link_x0020_DML" = $linkDmlUrl; "Link_x0020_DMS" = $linkDmsUrl; "URL" = $newSiteUrl}
            Disconnect-PnPOnline

            # Apply the template
            Connect-PnPOnline -Url $newSiteUrl -CurrentCredentials
            $null = Apply-PnPProvisioningTemplate -Path $templateFilePath
            Remove-Item -Path $templateFilePath -Force
           

            # Add LinkDML and LinkDMS to Abteilungslinks of newly created site. 
             $null = Add-PnPListItem -List "Abteilungslinks"-Values @{"URL" = $linkDmlUrl; "Title" = "DML"}
             $null = Add-PnPListItem -List "Abteilungslinks"-Values @{"URL" = $linkDmsUrl; "Title" = "DMS"}

            Write-Host "Site collection created and template applied at $newSiteUrl" -ForegroundColor Green
        } catch {
            Write-Host "An error occurred: $_.Exception.Message" -ForegroundColor Red
        }
    } else {
        Write-Host "Site collection already exists at $newSiteUrl" -ForegroundColor Yellow
    }
}
$web.Dispose()
