# JSON file path and text output file path
$jsonFile = "email_nations.json"
$outputTextFile = "Universities_Emails.txt"

# Function to extract emails from a webpage
function Get-EmailsFromPage {
    param (
        [string]$url
    )

    # Fetch the webpage content
    $response = Invoke-WebRequest -Uri $url
    $html = $response.Content

    # Use regex to find emails
    $emailPattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    $matches = [regex]::Matches($html, $emailPattern)

    # Return unique emails
    return $matches | Select-Object -Unique
}

# Read countries from JSON file
$countriesData = Get-Content -Raw -Path $jsonFile | ConvertFrom-Json
$countries = $countriesData.countries

# Prepare the text file by clearing or creating it
Set-Content -Path $outputTextFile -Value "List of Universities and Emails`n`n"
# Set up headers to simulate a browser request
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36"
}

# Iterate over each country to scrape university emails
foreach ($country in $countries) {
    Write-Host "Scraping emails for universities in $($country.name)..."

    # Example: Assume you have a base URL structure for universities
    # This part should be adjusted according to how the website structures data
    $baseUrl = "https://www.artuniversities.com/search?country=$($country.name)"

    # Example: Parse university pages (adjust based on real structure)
    $universityPages = Invoke-WebRequest -Uri $baseUrl -Headers $headers
    $universityUrls = $universityPages.Links.Href | Where-Object { $_ -like "*university*" }

    # Loop through each university
    foreach ($universityUrl in $universityUrls) {
        $universityName = $universityUrl.Split("/")[-1] # Extract the name
        $emails = Get-EmailsFromPage -url $universityUrl

        # Store result in text file if emails are found
        if ($emails.Count -gt 0) {
            Add-Content -Path $outputTextFile -Value "University Name: $universityName"
            foreach ($email in $emails) {
                Add-Content -Path $outputTextFile -Value "Email: $email"
            }
            Add-Content -Path $outputTextFile -Value "`n"  # New line between entries
        }
    }
}
Write-Host "Scraping complete. Results saved to $outputTextFile"
