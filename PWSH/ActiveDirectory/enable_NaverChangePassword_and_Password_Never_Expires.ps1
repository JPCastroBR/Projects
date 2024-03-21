Import-Module ActiveDirectory
Get-ADUser -Filter * -SearchBase "DC=SRV,DC=local" |  Set-ADUser -PasswordNeverExpires:$True -CannotChangePassword:$True