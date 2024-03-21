#
# Este Script foi criado a funcionalidade de agilizar a conexao remota as maquinas via UltraVNC
# Com o auxilio do GLPI e criação de Protocolos especificos para chamada Diretamente do VNC 
# Afim de agilizar a conexão remota para auxilio remoto
#

# Parametro recebido ao chamar o protocolo Recebendo o Nome da Maquina que irá se conectar
param($P)

# Funções para remoção dos campos desnecessários pois a conexão se dá pelo nome da maquina no DNS
$computador = $p.Split(':')[1]
$computador = $computador.Replace('/', '')
$computador = $computador.Replace("`n", '')

# Informar a senha das Maquinas para conexao remota
$Password = '12345abcd'

# Inicia o processo do VNC com os argumentos necessários para conexão
# -autoscaling = Redimenciona para 100% a escala do VNC
# -dsmplugin = Utiliza o Plugin de segurança
Start-Process -FilePath "C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe" -ArgumentList "$computador -autoscaling -password $password -dsmplugin SecureVNCPlugin64.dsm"

# Para o processo iniciado do powershell 
Stop-Process -Name "pwsh"