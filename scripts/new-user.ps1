. .\input-validation.ps1


# Get the params
$firstName = Read-ValidInput "First Name?"
$lastName = Read-ValidInput "Last Name?"
$region = Read-ValidInput "Region? (e.g., Europe, USA, Asia)"
$department = Read-ValidInput "Department? (e.g., IT, HR, Sales)"

# Checking
# Write-Output "$firstName $lastName $region $department"

# create user name
#   Rule: 
#           1. First 3 letters of first name (if less, use everything)
#           2. lastname 
#           3. all in lower 

# Handle first name length to generate username prefix
if ($firstName.Length -lt 3) {
    $prefix =$firstName.ToLower()
} else {
    $prefix =$firstName.Substring(0, 3).ToLower()
}

# Generate SamAccountName and UPN
$username = "$prefix$($lastName.ToLower())"
$upn = "$username@jh.local"

# Define target OU path based on region
$targetOU = "OU=Users,OU=$region,DC=jh,DC=local"

# Convert default password to secure string
$securePassword = ConvertTo-SecureString "Newnew123?" -AsPlainText -Force

# Create the AD user
New-ADUser `
    -Name "$firstName $lastName" `
    -GivenName $firstName `
    -Surname $lastName `
    -SamAccountName $username `
    -UserPrincipalName $upn `
    -Path $targetOU `
    -AccountPassword $securePassword `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Department $department

Write-Host "Successfully created user: $username in$region OU!" -ForegroundColor Green