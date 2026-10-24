# Validates the input 

function Read-ValidInput {
    param (
        # Ex: "First name?"
        [Parameter(Mandatory=$true)]
        [string]$PromptMessage
    )
    
    do {
        # Store the input value 
        $inputVal = Read-Host $PromptMessage

        # Check empty
        if ([string]::IsNullOrWhiteSpace($inputVal)) {
            Write-Host "Input cannot be empty. Please try again." -ForegroundColor Yellow
        }
    } while ([string]::IsNullOrWhiteSpace($inputVal))
    
    return $inputVal.Trim()
}