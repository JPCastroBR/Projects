# Definir o caminho onde os arquivos serão salvos
$caminho = "C:\Temp"

# Carregar os arquivos CSV
$usuariosIntranet = Import-Csv -Path "$caminho\usuarios_intranet.csv"

# Combinar os usuários dos dois sistemas
$usuariosTotais = $usuariosIntranet.SAMACCOUNTNAME + $usuariosMV.SAMACCOUNTNAME + $usuariosInteract.SAMACCOUNTNAME| Get-Unique

$usuariosTotais | Export-Csv -Path "$caminho\usuariosTotais.csv" -NoTypeInformation
# Obter todos os usuários do Active Directory e converter para maiúsculas
$usuariosAD = (Get-ADUser -Filter *).SamAccountName.ToUpper()

# Verificar usuários faltantes no AD
$usuariosFaltandoAD = $usuariosTotais | Where-Object { $_ -notin $usuariosAD }

# Exportar usuários faltantes para arquivo CSV
$usuariosFaltandoAD | ForEach-Object { [PSCustomObject]@{ CD_USUARIO = $_ } } | Export-Csv -Path "$caminho\faltando_usuarios_ad.csv" -NoTypeInformation

Write-Host "Operação concluída."
