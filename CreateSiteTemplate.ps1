$docLibUrl = "https://dev19.dccs-demo.at/sites/sitecoladmin/Templates" #DCCS
$adminSiteUrl = "https://dev19.dccs-demo.at/sites/sitecoladmin" #DCCS

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Input Form'
$form.Size = New-Object System.Drawing.Size(400,200)

# Label and Text Box for Site URL
$labelSiteUrl = New-Object System.Windows.Forms.Label
$labelSiteUrl.Text = 'Site URL:'
$labelSiteUrl.Location = New-Object System.Drawing.Point(10,20)
$labelSiteUrl.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($labelSiteUrl)

$textBoxSiteUrl = New-Object System.Windows.Forms.TextBox
$textBoxSiteUrl.Location = New-Object System.Drawing.Point(130,20)
$textBoxSiteUrl.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textBoxSiteUrl)

# Label and Text Box for Template Name
$labelTemplateName = New-Object System.Windows.Forms.Label
$labelTemplateName.Text = 'Template Name:'
$labelTemplateName.Location = New-Object System.Drawing.Point(10,50)
$labelTemplateName.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($labelTemplateName)

$textBoxTemplateName = New-Object System.Windows.Forms.TextBox
$textBoxTemplateName.Location = New-Object System.Drawing.Point(130,50)
$textBoxTemplateName.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textBoxTemplateName)

# OK Button
$button = New-Object System.Windows.Forms.Button
$button.Text = 'OK'
$button.Location = New-Object System.Drawing.Point(130,110)
$button.Size = New-Object System.Drawing.Size(250,20)
$button.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($button)
$form.AcceptButton = $button

# Display the Form
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $siteUrl = $textBoxSiteUrl.Text
    $templateName = $textBoxTemplateName.Text
    $savePath = Join-Path $PSScriptRoot ($templateName + ".pnp")


    Connect-PnPOnline -Url $siteUrl -CurrentCredentials
    Get-PnPProvisioningTemplate -Out $savePath  -Handlers Lists, Pages, Theme, SiteSettings, PageContents

    $fileUrl = $docLibUrl + "/" + $templateName + ".pnp"
    $fileUrl = $docLibUrl + "/" + $templateName + ".pnp"

    # Upload the template to SharePoint
    Connect-PnPOnline -Url $adminSiteUrl -CurrentCredentials
    Add-PnPFile -Path $savePath -Folder "/Templates" -NewFileName ($templateName + ".pnp")

    # Clean up: Delete the local file
    Remove-Item -Path $savePath -Force
}
