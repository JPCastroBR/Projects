# Importe o módulo ActiveDirectory
Import-Module ActiveDirectory

# Defina o caminho do arquivo de saída
$outputFile = "C:\Temp\usuarios_ad.csv"

# Obtenha uma lista de todos os usuários do Active Directory com os campos desejados
$users = Get-ADUser -Filter * -Properties sAMAccountName, cn, Enabled | Select-Object sAMAccountName, cn, Enabled

# Exporte a lista de usuários para um arquivo CSV
$users | Export-Csv -Path $outputFile -NoTypeInformation
