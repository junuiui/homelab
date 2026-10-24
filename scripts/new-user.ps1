########################
#                      #
# Creating User by Cmd #
#                      #
########################

. .\functions.ps1

# Get params
$firstName = Read-ValidInput "First Name?"
$lastName = Read-ValidInput "Last Name?"
$region = Read-ValidInput "Region? (e.g., Europe, Asia, USA)"
$department = Read-ValidInput "Department? (e.g., IT, HR, Sales)"


# Handle first name length to genearte username prefix
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
    Write-Host "[ERROR] Failed creating user: $username in $region OU" -ForegroundColor Red
}

