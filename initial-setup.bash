#!/bin/bash

# 1. Stäng av High Availability och Corosync (Kluster-tjänster)
systemctl disable --now pve-ha-lrm pve-ha-crm corosync

# 2. Stäng av Proxmox Storage Replication timer (letar efter replikeringsjobb varje minut)
systemctl disable --now pvesr.timer

# 3. Sänk Swappiness till 10 (Tvingar systemet att använda RAM istället för disk)
grep -q "^vm.swappiness=10" /etc/sysctl.conf || echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p

# 4. Sätt systemloggar (journald) till 'volatile' (skriver loggar enbart till RAM-minnet, raderas vid omstart)
sed -i 's/^#*Storage=.*/Storage=volatile/' /etc/systemd/journald.conf

# 5. Begränsa RAM-användningen för loggarna till maximalt 50MB
sed -i 's/^#*RuntimeMaxUse=.*/RuntimeMaxUse=50M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# 6. Ta bort "No valid subscription"-rutan i GUI
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid subscription'\),)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service

echo "Klar. Ladda om webbläsaren (Ctrl + F5) för att GUI-ändringen ska slå igenom."
