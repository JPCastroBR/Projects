#
# Este Script foi criado a funcionalidade de agilizar a conexao remota as maquinas via UltraVNC
# Com o auxilio do GLPI e criação de Protocolos especificos para chamada de um Shell
# Afim de agilizar a alguns processos como Reinicio de Spooler, Copia de Programas, Instalações, Reinicializações
# Conectando via Sessão do Powershell nas maquinas
#

# Parametro recebido ao chamar o protocolo Recebendo o Nome da Maquina que irá se conectar
param($P)
$option = 0
$Opcomputador = 0
$Servico = 0


# Definimos que todos os meses iriamos alterar o plano de fundo das maquinas para algumas campanhas internas
# Assim para não termos que ficar lembrando de ir e trocar o plano de fundo manualmente, toda vez que executamos o script
# Ele troca o arquivo do plano de fundo, e assim quando o usuario realiza o login na maquina busca a nova imagem
function planofundo {
    # Obtém o mês atual
    $mesAtual = Get-Date -Format "MM"

    # Constrói o nome do arquivo correspondente ao mês
    $arquivoParaCopiar = "C:\Temp\PLANO_DE_FUNDO_MES\plano_fundo_$mesAtual.jpg"

    # Verifica se o arquivo existe antes de copiá-lo
    if (Test-Path $arquivoParaCopiar) {
        # Lista de destinos
        $destinos = "C:\Temp\plano_de_fundo.jpg"

        # Loop para copiar o arquivo para cada destino
        foreach ($caminhoDestino in $destinos) {
            # Copia o arquivo para o destino
            Copy-Item -Path $arquivoParaCopiar -Destination $caminhoDestino -Force
            }
    } 
}

# Inicia a função de troca do plano de fundo
planofundo

# loop para exibição das Opções que o Shell executa
while ($option -ne 99) {

    # Foi criado uma opção para execução Manual do script ou via Protocolo
    if ($p -notlike '*:*' -and $Opcomputador -eq 0){
        Clear-Host
        $computador = Read-Host "Computador"
    }else {
        $computador = $p.Split(':')[1]
        $computador = $computador.Replace('/', '')
        $computador = $computador.Replace("`n", '')
    }


    # Efetuado a conexao na maquina remota e pegar o usuario logado no computador. 
    # muitas vezes necessário para verificação de quais politicas são aplicadas ao Usuario e a Maquina
    if ($Opcomputador -eq 0){
        Clear-Host
        $PSOption = New-PSSessionOption
        $PSOption.OpenTimeout = (New-Timespan -Minutes 5)
        $session = New-PSSession -ComputerName $computador -SessionOption $PSOption -ErrorAction Stop 
        $User = Invoke-Command -Session $session { ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1] }
        $Opcomputador = 1
    }
    
    #Efetua um teste de conexão, caso não seja possivel conectar encerasse o processo
    if (Test-Connection -TargetName $computador -Quiet -Count 1 -ErrorAction Ignore) { 
        Clear-Host

        # Opções Disponiveis
        Write-Output "Conectado: ($computador / $user)"
        Write-Output "Opções"
        Write-Output "  1 - Ping"
        Write-Output "  2 - Reiniciar o Computador"
        Write-Output "  3 - Reinstalar Ultravnc(64x)"
        Write-Output "  4 - Reiniciar Spooler"
        Write-Output "  5 - Reiniciar Serviço VNC"
        Write-Output "  6 - Copiar Navegadores"
        Write-Output "  7 - Corrigir Java SBS"
        Write-Output "  8 - Atualizar Politicas (GPUPDATE)"
        Write-Output "  9 - Corrigir Problemas de Rede"
        Write-Output "  10 - Instalar Programas"
        Write-Output "  11 - Instalar Driver Impressoras"
        Write-Output "  12 - Abrir VNC"
        Write-Output "  13 - Reinstalar Rocket Chat"
        Write-Output "  14 - Encerrar SIMNext e SIMPlus"
        Write-Output "  15 - Renomear Computador"
        Write-Output "  "
        Write-Output "  "
        Write-Output "  99 - Sair"
        $option = Read-Host "Opção"

        if ($option -eq 1)     <# Ping #> { 
            Write-Output "Opções"
            Write-Output "  1 - Ping computador conectado"
            Write-Output "  2 - Ping outro IP"
            Write-Output "  "
            Write-Output "  99 - Sair"

            $option = Read-Host "Qual opção? "
            if ($option -eq 1) {
                $qtd_ping = Read-Host "Quantidade ping"
                Test-Connection -TargetName $computador -Count $qtd_ping
            }
            elseif ($option -eq 2) {
                
                $IP = Read-Host "Digite o ip"
                $qtd_ping = Read-Host "Quantidade ping"
                Test-Connection -TargetName $IP -Count $qtd_ping
            }
            Start-Sleep -Seconds 10
        }

        elseif ($option -eq 2) <# Reiniciar de Computador #> { 
            # 
            # As vezes é necessário reiniciar um computador
            # ao realizar esta parte do codigo, registra-se o comando executado na maquina e o usuario que realizou. 
            #
            $Confirmar = Read-Host "Tem certeza que deseja reinciar o $computador (S/N)"
            if($Confirmar -eq 'S'){
                
                $Time_Pasta = Get-Date -Format "MM_yyyy"
                $time = Get-Date

                New-Item -Path "\\$Computador\C$\LOG_PC\$Computador" -ItemType Directory -ErrorAction Ignore
                $deployment = "\\$Computador\C$\LOG_PC\$Computador\Status_$Time_Pasta.txt"
                $user_ti = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                add-content -path $deployment -value "$time - Reiniciado pela TI ($user_ti)"
                Invoke-Command -Session $session {
                    Restart-Computer -ComputerName localhost -force
                } -AsJob

                Write-Output "Reiniciando ($computador) ..... Aguarde (30s)"
                Start-Sleep -Seconds 30
                Test-Connection -TargetName $computador -Count 20 
            }
        }

        elseif ($option -eq 3) <# Reinstalar Ultravnc(64x) #>{
            #
            # Podendo ser usado para Instalar ou Reinstalar o UltraVNC na maquina
            #

            Write-Output 'Reinstall Ultravnc(64x)'
            Write-Output 'Parando Serviço'
            Invoke-Command -Session $session { taskkill.exe /IM winvnc /F } -AsJob
            #
            # Realiza a copia do arquivo necessário para a maquina, podendo ser um caminho na rede ou internet
            # Utilizando o C:\Temp\ARQUIVOS como repositorio dos arquivos na rede
            #
            $file = "C:\Temp\ARQUIVOS\Programas\UltraVNC\UltraVnc_1240_X64.msi"
            New-Item -Path "\\$computador\c$\Temp\" -ItemType Directory -ErrorAction Ignore
            Copy-Item -Path $file -Destination "\\$computador\c$\Temp\"          
            Start-Sleep -Seconds 5  
            
            Write-Output 'Removendo Arquivos' 
            Invoke-Command -Session $session { Remove-Item "C:\Program Files\uvnc bvba" -Force -Recurse }
            Start-Sleep -Seconds 5 

            Write-Output 'Aguarde Instalando'
            Invoke-Command -Session $session -ScriptBlock {
                c:\temp\UltraVnc_1240_X64.msi /Quiet /norestart
            }
            Start-Sleep -Seconds 15 

            Write-Output 'Copiando Arquivos'
            Invoke-Command -Session $session -ScriptBlock {
                Stop-Service -Name uvnc_service
                Stop-Process -Name winvnc -Force
            } -AsJob    

            Start-Sleep -Seconds 5 

            # Arquivos Padroes, criados para criptografia e senha 
            # Defina da melhor forma que se adeque ao seu processo
            $file1 = "C:\Temp\ARQUIVOS\Programas\UltraVNC\UltraVNC_Auth_Encryption.ini" 
            $file2 = "C:\Temp\ARQUIVOS\Programas\UltraVNC\20230208_Server_ClientAuth.pubkey"
            $file3 = "C:\Temp\ARQUIVOS\Programas\UltraVNC\20230208_Viewer_ClientAuth.pkey"
            Copy-Item -Path $file1,$file2,$file3 -Destination "\\$computador\c$\Program Files\uvnc bvba\UltraVnc\" -Force
            Rename-Item -Path "\\$computador\c$\Program Files\uvnc bvba\UltraVnc\UltraVNC_Auth_Encryption.ini" -NewName "UltraVNC.ini"
            Rename-Item -Path "\\$computador\c$\Program Files\uvnc bvba\UltraVnc\20230208_Server_ClientAuth.pubkey" -NewName "Server_ClientAuth.pubkey"
            Rename-Item -Path "\\$computador\c$\Program Files\uvnc bvba\UltraVnc\20230208_Viewer_ClientAuth.pkey" -NewName "Viewer_ClientAuth.pkey"
            Start-Sleep -Seconds 5 

            Write-Output 'Iniciando o Serviço'
            Invoke-Command -Session $session -ScriptBlock {
                Start-Service -Name uvnc_service
            } -AsJob
            Start-Sleep -Seconds 5 
            
            Write-Output 'Serviço Iniciado'
            Start-Sleep -Seconds 10 
        }

        elseif ($option -eq 4) <# Reiniciar Spooler #>{
            #
            # Reinicia o Spooler da maquina, devido a alguns usuarios não ter permissões para realizar
            # Apaga também arquivos presos
            #
            Write-Output "Parando Serviço e limpando fila de impressão"
            Invoke-Command -Session $session { 
                    Stop-Service -Name Spooler 
                    Remove-Item -Path "c:\Windows\System32\spool\PRINTERS\*.*" -recurse -Force -ErrorAction Ignore
                    Start-Service -Name Spooler
                } -AsJob
            Start-Sleep -Seconds 5
        }
        elseif ($option -eq 5) <# Reiniciar Serviço VNC #>{
           Invoke-Command -Session $session { Restart-Service -Name uvnc_service }    
           Start-Sleep -Seconds 5
        }
        elseif ($option -eq 6) <# Copiar Navegadores #>{
            Write-Output "Opções"
            Write-Output "  1 - CentBrowser"
            Write-Output "  2 - Maxthon"
            Write-Output "  3 - Chromium"
            Write-Output "  4 - Firefox (SBS)"
            Write-Output "  5 - CentBrowser no Usuario"
            Write-Output " "

            $option2 = Read-Host "Opção"

            If ($option2 -eq 1) {
                Write-Output 'Copiando CentBrowser...'
                $file = "C:\Temp\ARQUIVOS\Programas\CentBrowser\"
                Remove-Item -Path "\\$computador\c$\ProgramData\CentBrowser\" -recurse -Force -ErrorAction Ignore
                Copy-Item -Path $file -Destination "\\$computador\c$\ProgramData\" -recurse -Force
            }
            elseif($option2 -eq 2){
                Write-Output 'Copiando Maxthon...'
                $file = "C:\Temp\ARQUIVOS\Programas\Maxthon\"
                Remove-Item -Path "\\$computador\c$\ProgramData\Maxthon\" -recurse -Force -ErrorAction Ignore
                Copy-Item -Path $file -Destination "\\$computador\c$\ProgramData\"     -recurse -Force
            }
            elseif($option2 -eq 3){
                Write-Output 'Copiando Chromium...'
                $file = "C:\Temp\ARQUIVOS\Programas\Chromium\chrome-bin\"
                Remove-Item -Path "\\$computador\c$\ProgramData\Chromium\" -recurse -Force -ErrorAction Ignore
                Copy-Item -Path $file -Destination "\\$computador\c$\ProgramData\Chromium\chrome-bin\" -recurse -Force
                $Local = 'C:\Temp\ARQUIVOS\Programas\MV\Chromium\User Data\'

                #$Destino = Pasta que será enviado os arquivos
                $Destino = "\\$computador\c$\Users\$user\appdata\Local\Chromium\User Data\"
                #Efetua a copia dos arquivos
                Copy-Item -Path $Local -Destination $Destino -recurse -Force
            }
            elseif($option2 -eq 4){
                Write-Output 'Copiando...'
                $file = 'C:\Temp\ARQUIVOS\Programas\Mozilla_51\firefox_bin\'
                Remove-Item -Path "\\$computador\c$\ProgramData\Mozilla\" -recurse -Force -ErrorAction Ignore
                Copy-Item -Path $file -Destination "\\$computador\c$\ProgramData\Mozilla\firefox_bin\" -recurse -Force
            }
            elseif($option2 -eq 5){
                Write-Output 'Copiando...'
                $file = "C:\Temp\ARQUIVOS\Programas\CentBrowser\"
                #Remove-Item -Path "\\$computador\c$\users\$User\appdata\Roaming\CentBrowser" -recurse -Force -ErrorAction Ignore
                Copy-Item -Path $file -Destination "\\$computador\c$\users\$User\appdata\Roaming\CentBrowser" -recurse -Force
            }
            Start-Sleep -Seconds 5 
        }
        elseif ($option -eq 8) <# Atualizar Politicas (GPUPDATE) #>{
            Write-Output "GPUPDATE /FORCE /TARGET:USER
            1 - GPUPDATE Geral
            2 - GPUPDATE Usuario
            3 - GPUPDATE Computador

            99 -  Sair
            "

            $GPUPDATE = Read-Host "Qual Serviço"
            if($GPUPDATE -eq 1){
                Invoke-Command -Session $session { gpupdate.exe /force } -AsJob
            }elseif($GPUPDATE -eq 2){
                Invoke-Command -Session $session { gpupdate.exe /force /target:user} -AsJob
            }elseif($GPUPDATE -eq 3){
                Invoke-Command -Session $session { gpupdate.exe /force /target:computer} -AsJob
            }
            Start-Sleep 2
        }
        elseif ($option -eq 9) <# Corrigir Problemas de Rede #>{
            Write-Output 'Aplicando correções de rede'
            Invoke-Command -Session $session { 
                ipconfig /release 
                ipconfig /renew
                ipconfig /flushdns
            } -AsJob
            Write-Output 'Finalizado'
            Start-Sleep -Seconds 10
        }
        elseif ($option -eq 10) <# Instalar Programas #>{
            #Clear-Host
            Write-Output "Qual programa Deseja Instalar
            1 - Google Chrome Enterprise 110.0.5481.104
            2 - LibreOffice 7.2.3
            3 - PowerShell 7.2.9
            4 - Acrobat Reader DC 2019.008.20071
            5 - Rocket.Chat
            6 - Antivirus (Bitdefender)
            7 - Weasis 4.1.2 (Visualizador ImagemMV)
            8 - OCS Inventory
            
            99 -  Sair
            "
            $Servico = Read-Host "Qual Serviço"

            if ($Servico -eq 1) {
                $file = "C:\Temp\ARQUIVOS\Programas\_MSI\CHROME\GoogleChromeStandaloneEnterprise110_0_5481_104.msi"
                Copy-Item -Path $file -Destination "\\$computador\c$\Temp\" -Recurse
                Invoke-Command -Session $session -ScriptBlock {
                    c:\temp\GoogleChromeStandaloneEnterprise110_0_5481_104.msi /Quiet /norestart
                } -AsJob
            }
            elseif ($Servico -eq 2) {
                $file = "C:\Temp\ARQUIVOS\Programas\_MSI\LibreOffice_7.2.3_Win_x64.msi"
                Copy-Item -Path $file -Destination "\\$computador\c$\Temp\" -Recurse
                Invoke-Command -Session $session -ScriptBlock {
                    c:\temp\LibreOffice_7.2.3_Win_x64.msi /Quiet /norestart
                } -AsJob
            }
            elseif ($Servico -eq 3) {
                $file = "C:\Temp\ARQUIVOS\Programas\_MSI\PowerShell-7.2.9-win-x64.msi"
                Copy-Item -Path $file -Destination "\\$computador\c$\Temp\" -Recurse
                Invoke-Command -Session $session -ScriptBlock {
                    c:\temp\PowerShell-7.2.9-win-x64.msi /Quiet /norestart
                } -AsJob
            }
            elseif ($Servico -eq 4) {
                $file = "C:\Temp\ARQUIVOS\Programas\_MSI\Acrobat_Reader_DC_2019_008_20071_pt_BR\"
                Copy-Item -Path $file -Destination "\\$computador\c$\Temp\" -Recurse
                Invoke-Command -Session $session -ScriptBlock {
                    C:\Temp\Acrobat_Reader_DC_2019_008_20071_pt_BR\AcroRead.msi /Quiet /norestart
                } -AsJob
            }
            elseif ($Servico -eq 5) {
                $file1 = "C:\Temp\ARQUIVOS\Programas\RocketChat\rocketchat-3.9.11-win-x64.msi"
                Copy-Item -Path $file1 -Destination "\\$computador\c$\Temp\" -Recurse -Force
                Invoke-Command -Session $session { taskkill.exe /IM Rocket.Chat /F } -AsJob
                Start-Sleep -Seconds 2 
                Invoke-Command -Session $session -ScriptBlock {
                    C:\Temp\rocketchat-3.9.11-win-x64.msi /quiet
                } -AsJob
            }
            elseif ($Servico -eq 6) {
                $file1 = "C:\Temp\ARQUIVOS\Programas\ANTI-VIRUS\Bitdefender\BEST_downloaderWrapper.msi"
                Copy-Item -Path $file1 -Destination "\\$computador\c$\Temp\" -Recurse -Force
                Start-Sleep -Seconds 2
                
                Invoke-Command -Session $session -ScriptBlock { Start-Process -FilePath "c:\TEMP\BEST_downloaderWrapper.msi" } 
                Start-Sleep 2s
                Invoke-Command -Session $session -ScriptBlock { Get-process MSI*.tmp } 
                Start-Sleep 20s
            }
            elseif ($Servico -eq 7) {
                $file1 = "C:\Temp\ARQUIVOS\Programas\Weasis\weasis-4.1.2-x86-64.msi"
                Copy-Item -Path $file1 -Destination "\\$computador\c$\Temp\" -Recurse -Force

                Invoke-Command -Session $session -ScriptBlock { Start-Process C:\Temp\weasis-4.1.2-x86-64.msi /quiet} -AsJob
            }
            elseif ($Servico -eq 8) {
                $file1 = "C:\Temp\OCSWindows2-9-2-0\OCS-Windows-Agent-Setup-x64.exe"
                Copy-Item -Path $file1 -Destination "\\$computador\c$\Temp\" -Recurse -Force
                $file2 = "C:\Temp\OCSWindows2-9-2-0\OPTIONS.TXT"
                Copy-Item -Path $file2 -Destination "\\$computador\c$\Temp\" -Recurse -Force
                Invoke-Command -Session $session { Restart-Service -Name "OCS Inventory Service" }
            }
            Start-Sleep -Seconds 5 
        }
        elseif ($option -eq 11) <# Instalar Driver Impressoras #>{
            $Servico = 0
            while($Servico -ne 99) {
                Clear-Host
                Write-Output "Impressoras da Instituição"
                Write-Output "  1 - Samsung M332x 382x 402x Series"
                Write-Output "  2 - Samsung M337x 387x 407x Series"
                Write-Output "  3 - Zebra.v5 (GC420t, GK420t, GT800) "
                Write-Output "  4 - Zebra.v8 (ZD230-203, ZT230-200) "
                Write-Output "  5 - HP LaserJet Professional M1132 MFP"
                Write-Output "  6 - ELGIN L42/L43Pro"
                Write-Output "  7 - EPSON L355"
                Write-Output "  8 - EPSON L365"
                Write-Output "  9 - EPSON L375"
                Write-Output "  10 - Gainsha GS 2208D"
                Write-Output " "
                Write-Output "99 -  Sair
                "

                $Servico = Read-Host "Qual Impressora"
                if ($Servico -eq 1) <#Samsung_M332x_382x_402x_Series#> {
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\Samsung_M332x_382x_402x_Series"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\Samsung_M332x_382x_402x_Series" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\Samsung_M332x_382x_402x_Series\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "Samsung M332x 382x 402x Series"
                    }
                }
                elseif ($Servico -eq 2) <#Samsung_M337x_387x_407x_Series#> {
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\Samsung_M337x_387x_407x_Series"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\Samsung_M337x_387x_407x_Series\" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\Samsung_M337x_387x_407x_Series\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "Samsung M337x 387x 407x Series"}
                }
                elseif ($Servico -eq 3) <#Zebra_v5#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\Zebra_v5"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\Zebra_v5" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\Zebra_v5\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "ZDesigner GC420t (EPL)"
                        Add-PrinterDriver -Name "ZDesigner GC420t"
                        Add-PrinterDriver -Name "ZDesigner GK420t (EPL)"
                        Add-PrinterDriver -Name "ZDesigner GK420t"
                        Add-PrinterDriver -Name "ZDesigner GT800 (EPL)"
                        Add-PrinterDriver -Name "ZDesigner GT800 (ZPL)"
                    }
                }
                elseif ($Servico -eq 4) <#Zebra_v8#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\Zebra_v8"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\Zebra_v8" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\Zebra_v8\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "ZDesigner ZD230-203dpi ZPL"
                        Add-PrinterDriver -Name "ZDesigner ZT230-200dpi ZPL"
                    }
                }
                elseif ($Servico -eq 5) <#HP_LaserJet_Professional_M1132_MFP#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\HP_LaserJet_Professional_M1132_MFP"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\HP_LaserJet_Professional_M1132_MFP" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\HP_LaserJet_Professional_M1132_MFP\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "HP LaserJet Professional M1132 MFP"
                    }
                }
                elseif ($Servico -eq 6) <#ELGIN L42Pro_L43Pro#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\ELGIN_L42Pro_L43Pro"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\ELGIN_L42Pro_L43Pro" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\ELGIN_L42Pro_L43Pro\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "ELGIN L42Pro"
                        Add-PrinterDriver -Name "ELGIN L43Pro"
                    }
                }
                elseif ($Servico -eq 7) <#EPSON_L355#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\EPSON L355 Series"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\EPSON L355 Series" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\EPSON L355 Series\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "EPSON L355 Series"
                    }
                } 
                elseif ($Servico -eq 8) <#EPSON_L365#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\EPSON_L365"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\EPSON_L365" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\EPSON_L365\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "EPSON L365 Series"
                    }
                }
                elseif ($Servico -eq 9) <#EPSON_L375#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\EPSON_L375"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\EPSON_L375" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\EPSON_L375\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "EPSON L375 Series"                  
                    }
                }
                elseif ($Servico -eq 10) <#Gainsha_GS_2208D#>{
                    $file = "C:\Temp\ARQUIVOS\Programas\IMPRESSORAS\_Drivers_SCM\Gainsha_GS_2208D"
                    Copy-Item -Path $file -Destination "\\$computador\c$\Temp\Gainsha_GS_2208D" -Recurse -ErrorAction Ignore
                    Invoke-Command -Session $session -ScriptBlock {
                        Get-ChildItem "C:\Temp\Gainsha_GS_2208D\" -Recurse -Filter "*inf" | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } 
                        Add-PrinterDriver -Name "Gainscha GS-2208D"
                    }
                }                 
            }           
        }
        elseif ($option -eq 12) <# Abrir VNC #>{
            $Password = '12345abcd'
            cmd.exe /V /C "C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe" $computador -autoscaling -password $Password -dsmplugin SecureVNCPlugin64.dsm
        }           
        elseif ($option -eq 13) <# Reinstalar Rocket Chat #>{
            Write-Output 'Parando Serviço'
            Invoke-Command -Session $session { taskkill.exe /IM Rocket.Chat /F } -AsJob
            Write-Output 'Removendo Arquivos'
            Remove-Item -Path "\\$computador\c$\Users\$user\appdata\Roaming\rocket.Chat\" -recurse -Force -ErrorAction Ignore 
            Start-Sleep -Seconds 5
            Write-Output 'Aplicando GPUPDATE'
            Invoke-Command -Session $session { gpupdate.exe /force /target:user} -AsJob

        }
        elseif ($option -eq 14) <# Encerrar SIMNext e SIMPlus #>{
            Invoke-Command -Session $session { taskkill.exe /IM SIMNext /F } -AsJob
            Invoke-Command -Session $session { taskkill.exe /IM SIMNext.LocalRecording /F } -AsJob
        }
        elseif ($option -eq 15) <# Renomear Computador #>{
            $NewNameComputer = Read-Host "Qual o novo nome para o $computador"
            $Credencial = Get-Credential
            Rename-Computer -ComputerName $computador -NewName $NewNameComputer -DomainCredential $Credencial -Force
            Start-Sleep 3
        }          
        elseif ($option -eq 99) {
            Exit-PSSession
            $option = 99
        }
    }
    else{
        $option = 99
    }
}
Stop-Process -Name pwsh -Force
Exit