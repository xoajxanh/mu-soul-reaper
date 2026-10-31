Set-Location "d:\MUVH\android\mu-soul-reaper"
& git add .
& git commit -m "chore: initial project setup, tools, customer mod, and web_active"
& git log -n 1 --stat | ForEach-Object { Write-Host $_ }
