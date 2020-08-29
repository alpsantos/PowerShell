# -----------------------------------------------
# auth 
# -----------------------------------------------

$zabbixURL = "https://zabbixserver.test.com/zabbix/"

$zabbixAPIURL = $zabbixURL + "api_jsonrpc.php"
$zabbixGraphURL = $zabbixURL + "chart2.php?graphid="
$baseJSON = @{ "jsonrpc" = "2.0"; "id" = 1 }

$user = "usert"
$password = "pass"

$imageRootDIR = "C:\zabbix_graphs\"