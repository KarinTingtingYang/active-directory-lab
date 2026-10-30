# New-LabUsers.ps1 - bulk-create AD users from a CSV file
Import-Module ActiveDirectory

$csvPath  = 'C:\Lab\users.csv'
$domainDN = (Get-ADDomain).DistinguishedName      # DC=lab,DC=internal
$dnsRoot  = (Get-ADDomain).DNSRoot                # lab.internal
$password = Read-Host -AsSecureString 'Initial password for new users'

foreach ($u in Import-Csv -Path $csvPath) {
    $sam = $u.SamAccountName

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Warning "$sam already exists - skipped"
        continue
    }

    $params = @{
        Name                  = "$($u.FirstName) $($u.LastName)"
        GivenName             = $u.FirstName
        Surname               = $u.LastName
        SamAccountName        = $sam
        UserPrincipalName     = "$sam@$dnsRoot"
        Department            = $u.Department
        Path                  = "OU=$($u.OU),$domainDN"
        AccountPassword       = $password
        Enabled               = $true
        ChangePasswordAtLogon = $true
    }
    New-ADUser @params

    if ($u.Department -eq 'Finance') {
        Add-ADGroupMember -Identity 'SG-Finance' -Members $sam
    }
    Write-Host "Created $sam" -ForegroundColor Green
}