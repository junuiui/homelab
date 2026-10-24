[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Provide the email (UPN) of the user to offboard.")]
    [string]$Email
)

########################
#                      #
#  Offboarding Script  #
#                      #
########################

$targetOU = "OU=Disabled Users,DC=jh,DC=local"

# Search user by email (UserPrincipalName)
$user = Get-ADUser -Filter "UserPrincipalName -eq '$Email'"
if (-not $user) {
    Write-Host "[ERROR] User with email '$Email' not found in Active Directory." -ForegroundColor Red
    exit
}

try {
    # Disable account
    Disable-ADAccount -Identity $user.SamAccountName
    Write-Host "[INFO] Disabled account: $Email" -ForegroundColor Yellow

    # Remove group memberships except Domain Users
    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName
    foreach ($group in $groups) {
        if ($group.Name -ne "Domain Users") {
            Remove-ADGroupMember -Identity $group.DistinguishedName -Members $user.SamAccountName -Confirm:$false
            Write-Host "[INFO] Removed from group: $($group.Name)" -ForegroundColor DarkYellow
        }
    }

    # Move object to the disabled users OU
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $targetOU

    Write-Host "Successfully offboarded user: $Email!" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to offboard user $Email. Error: $_" -ForegroundColor Red
}