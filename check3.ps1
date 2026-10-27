$conn = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    "PORT 3000 LISTENING - PID: $($conn.OwningProcess)" | Out-File 'D:\码道云\demo\port3.txt' -Encoding utf8
} else {
    "PORT 3000 NOT LISTENING" | Out-File 'D:\码道云\demo\port3.txt' -Encoding utf8
}
"---NODE PROCESSES---" | Out-File 'D:\码道云\demo\port3.txt' -Append -Encoding utf8
Get-Process node -ErrorAction SilentlyContinue | Select-Object Id,StartTime | Format-Table -AutoSize | Out-File 'D:\码道云\demo\port3.txt' -Append -Encoding utf8