param([string]$hostid = 11521, [string] $infile = 0, [string] $startDate = "now-30d", [string] $endDate = "now" )

# period: now-30d

# -----------------------------------------------
. "$PSScriptRoot\AppConfig.ps1"
# -----------------------------------------------

try {

    if ($hostid -eq "") { throw "No hostid param." }

    # Get login token.
    $authJSON = $baseJSON.clone()
    $authJSON.method = "user.login"
    $authJSON.params = @{ "user" = $user; "password" = $password }
    $login = Invoke-RestMethod -Uri $zabbixAPIURL -Body ($authJSON | ConvertTo-Json) -method POST -ContentType "application/json"
    $baseJSON.auth = $login.result

    # Set Cookie.
    $zabbixDomain = $zabbixURL
    $session = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
    $cookie = New-Object -TypeName System.Net.Cookie
    $cookie.Name = "zbx_sessionid"
    $cookie.Value = $login.result
    $session.Cookies.Add($zabbixDomain, $cookie)

    # get hostids
    $hostGetJSON = $baseJSON.clone()
    $hostGetJSON.method = "host.get"
    $hostGetJSON.params = @{ "output" = "extend"; "hostids" = $hostid } #11521
    $hostGetResult = Invoke-WebRequest -Uri $zabbixAPIURL -WebSession $session -Body ($hostGetJSON | ConvertTo-Json) -method POST -ContentType "application/json" -UseBasicParsing
    $hosts = ($hostGetResult.toString() | ConvertFrom-Json).result

    foreach ($host_ in $hosts) {
        $hostname = ($host_.name -replace ":", "_")
        $hostID = $host_.hostid

        # get graphids per host.
        $graphGetJSON = $baseJSON.clone()
        $graphGetJSON.method = "graph.get"
        $graphGetJSON.params = @{ "output" = "extend"; "hostids" = $hostID }
        $graphGetResult = Invoke-WebRequest -Uri $zabbixAPIURL -WebSession $session -Body ($graphGetJSON | ConvertTo-Json) -method POST -ContentType "application/json" -UseBasicParsing
        $graphs = ($graphGetResult.toString() | ConvertFrom-Json).result
        
        $result = @()

        foreach ($graph in $graphs) {

            $graphURL = $zabbixGraphURL + $graph.graphid + '&from=' + $startDate + '&to=' + $endDate + "&profileIdx=web.graphs.filter&width=800&height=200"
            
            if ($infile -eq 1) {
                
                $dir = $imageRootDIR + $hostname
                [void](New-Item -ItemType Directory -Force $dir)
                
                $outputDir = $dir + "\" + [Guid]::NewGuid().ToString() + ".png"

                Invoke-WebRequest -Uri $graphURL -WebSession $session -Outfile $outputDir -UseBasicParsing

                $data = [ordered]@{
                    graphid = $graph.graphid
                    name    = $graph.name
                    imageFile     = $outputDir
                }
            }
            else {

                [byte[]]$b = (Invoke-WebRequest -Uri $graphURL -WebSession $session -UseBasicParsing).Content
                $b64 = "data:image/jpeg;base64," + [Convert]::ToBase64String($b)

                $data = [ordered]@{
                    graphid  = $graph.graphid
                    name     = $graph.name
                    imageB64 = $b64
                }
            }

            $Obj = New-Object -TypeName PSObject -property $data
            $result += $Obj
        }

        $result
    }
}
catch {
    throw $_
}