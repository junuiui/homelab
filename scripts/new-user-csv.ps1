[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Provide the path to the CSV")]
    [string]$csvPath
)

########################
#                      #
# Creating User by Csv #
#                      #
########################

# Usage: .\new-user-csv.ps1 [file-path]

. .\functions.ps1

# Reading csv
# check 
if (-not (Test-Path $csvPath)) {
    Write-Host "CSV file not found at: $csvPath" -ForegroundColor Red
    exit
}

# read
$users = Import-Csv $csvPath

# imply
foreach ($row in $users) {
    $firstName = $row.FirstName.Trim()
    $lastName = $row.LastName.Trim()
    $region = $row.Region.Trim()
    $department = $row.Department.Trim()

    if ([string]::IsNullOrWhiteSpace($firstName) -or [string]::IsNullOrWhiteSpace($lastName) -or [string]::IsNullOrWhiteSpace($region)) {
        Write-Host "[ERROR] Input cannot be empty. Skipping.." -ForegroundColor Yellow
        continue
    }

    #   first name prefix should be <= 3
    $prefix = getFirstNamePrefix $firstName

    # Generate username and UPN
    $username = "$prefix$($lastName.ToLower())"
    $upn = "$username@jh.local"

    # Define target OU path based on region
    $targetOU = "OU=Users,OU=$region,DC=jh,DC=local"

    # password setup
    $pw = ConvertTo-SecureString "Newnew123?" -AsPlainText -Force

    # Create AD User
    try {
        New-ADUser `
            -Name "$firstName $lastName" `
            -GivenName $firstName `
            -Surname $lastName `
            -SamAccountName $username `
            -UserPrincipalName $upn `
            -Path $targetOU `
            -AccountPassword $pw `
            -Enable $true `
            -PasswordNeverExpires $true `
            -Department $department

        Write-Host "Successfully created user: $username in $region OU!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed creating user: $username. Error: $_" -ForegroundColor Red
    }
}