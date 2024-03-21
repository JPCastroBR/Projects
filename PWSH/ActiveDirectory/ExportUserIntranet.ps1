# Importar a biblioteca MySQL
Add-Type -Path "C:\Program Files (x86)\MySQL\Connector NET 8.0\MySql.Data.dll"

# Criar a string de conexão
$Servidor = '192.16.0.100'
$Database = 'dbmysql'
$User =     'user'
$Password = 'user'

$connectionString = "server=$servidor;port=3306;database=$Database;user=$User;password=$Password;"

try {
    # Criar a conexão com o banco de dados
    $connection = New-Object MySQL.Data.MySqlClient.MySqlConnection($connectionString)

    # Abrir a conexão
    $connection.Open()

    # Executar a consulta
    $query = @"
    SELECT 
        '' AS SAMACCOUNTNAME,
        '' AS CN,
        '' AS DISPLAYNAME,
        '' AS GIVENNAME,
        '' AS SN,
        '' AS DEPARTMENT,
        '' AS SN_ATIVO,
        '' AS MAIL,
        '' AS TITLE
    FROM 
        Dual
    ORDER BY 1
"@

    $command = New-Object MySQL.Data.MySqlClient.MySqlCommand($query, $connection)
    $reader = $command.ExecuteReader()

    # Caminho do arquivo CSV
    $csvPath = "C:\Temp\usuarios_intranet.csv"

    # Criar um DataTable para armazenar os resultados
    $dataTable = New-Object System.Data.DataTable
    $dataTable.Load($reader)

    # Escrever os resultados no arquivo CSV
    $dataTable | Export-Csv -Path $csvPath -NoTypeInformation

    Write-Host "Consulta concluída. Resultados salvos em: $csvPath"

} catch {
    # Capturar erros
    Write-Error "Erro durante a conexão ou consulta: $($_.Exception.Message)"
} finally {
    # Fechar o reader e a conexão (sempre executar)
    if ($reader) {
        $reader.Close()
    }
    if ($connection.State -eq "Open") {
        $connection.Close()
    }
}
