Clear-Host
# Importar e executar o script de exportação de dados
C:\Temp\ExportUserIntranet.ps1
C:\Temp\Compara_usuarios_identifica_faltantes.ps1

# Agora que o script de exportação foi executado, continue com o resto do seu script
Write-Host "Script de exportação de dados concluído. Continuando com o restante do script..."


# Caminho do arquivo CSV com os dados atualizados
$csvPathIntranet = "C:\Temp\usuarios_intranet.csv"

# Caminho do arquivo de log
$logPath = "C:\Temp\log_atualizacao_usuarios_ad.txt"
$logPathUsuariosNaoCadastrados = "C:\Temp\UsuariosNaoEncontrados.txt"

# Importar o arquivo CSV
$usuariosAtualizadosIntranet    = Import-Csv -Path $csvPathIntranet

# Inicializar o log
$timestampInicio = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestampInicio] Início da atualização dos usuários do Active Directory." | Out-File -Append -FilePath $logPath

# Obter todos os usuários do Active Directory uma vez
$adUsers = Get-ADUser -Filter * -SearchBase "DC=SRV,DC=local"

# Loop através dos usuários atualizados
foreach ($usuario in $usuariosAtualizadosIntranet) {
    # Converter o nome de usuário para minúsculas
    $samAccountNameCSV = $usuario.SAMACCOUNTNAME.ToLower()

    # Encontrar o usuário correspondente no Active Directory
    $adUser = $adUsers | Where-Object { $_.SamAccountName.ToLower() -eq $samAccountNameCSV }

    # Verificar se o usuário existe no Active Directory
    if ($adUser) {        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        if ($usuario.DISPLAYNAME -ne "")    { Set-ADUser -Identity $adUser.SamAccountName -DisplayName $usuario.DISPLAYNAME }
        if ($usuario.GIVENNAME -ne "")      { Set-ADUser -Identity $adUser.SamAccountName -GivenName $usuario.GIVENNAME }
        if ($usuario.SN -ne "")             { Set-ADUser -Identity $adUser.SamAccountName -Surname $usuario.SN }
        if ($usuario.MAIL -ne "")           { Set-ADUser -Identity $adUser.SamAccountName -EmailAddress $usuario.MAIL }
        if ($usuario.DEPARTMENT -ne "")     { Set-ADUser -Identity $adUser.SamAccountName -Department $usuario.DEPARTMENT }
        if ($usuario.TITLE -ne "")          { Set-ADUser -Identity $adUser.SamAccountName -Title $usuario.TITLE }
            else {"$($usuario.SAMACCOUNTNAME)" | Out-File -Append -FilePath "C:\Temp\log_usuario_sem_funçao.txt" }

        # Ativar ou desativar o usuário conforme necessário
        if ($usuario.SN_ATIVO -eq "true") {
            Enable-ADAccount -Identity $adUser.SamAccountName
            #Write-Host "Usuário $($usuario.SAMACCOUNTNAME) Atualizado e ativado."
            "[$timestamp] Usuário $($usuario.SAMACCOUNTNAME) Atualizado e ativado." | Out-File -Append -FilePath $logPath
        } 

        elseif ($usuario.SN_ATIVO -eq "false") {   
            Disable-ADAccount -Identity $adUser.SamAccountName
            #Write-Host "Usuário $($usuario.SAMACCOUNTNAME) Atualizado e desativado."
            "[$timestamp] Usuário $($usuario.SAMACCOUNTNAME) Atualizado e desativado." | Out-File -Append -FilePath $logPath
        }
    } else {
        Write-Warning "Usuário $($usuario.SAMACCOUNTNAME) não encontrado no Active Directory."
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] AVISO: Usuário $($usuario.SAMACCOUNTNAME) não encontrado no Active Directory." | Out-File -Append -FilePath $logPathUsuariosNaoCadastrados
    }
}

# Adicionar mensagem de conclusão ao log
$timestampFim = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestampFim] Fim da atualização dos usuários do Active Directory." | Out-File -Append -FilePath $logPath

Write-Host "Operação concluída. Logs salvos em: $logPath"

# Excluir o arquivo CSV após a conclusão do script
Remove-Item -Path $csvPathIntranet -Force

Write-Host "Arquivo CSV removido com sucesso."
