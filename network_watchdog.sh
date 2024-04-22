#!/bin/bash

# Comptador de pings fallits
failed_pings=0

while true; do
    # Fer ping a l'adreça IP
    ping -c 1 192.168.1.2 > /dev/null
    
    # Comprovar si el ping va fallar
    if [ $? -ne 0 ]; then
        ((failed_pings++))
        echo "Ping fallit. Comptador: $failed_pings"
    else
        failed_pings=0
        echo "Ping exitós."
    fi
    
    # Comprovar si hi ha tres pings fallits consecutius
    if [ $failed_pings -eq 3 ]; then
        echo "Tres pings fallits consecutius. Apagant les màquines virtuals i reiniciant el servidor Proxmox..."
        # Apagar totes les màquines virtuals
        qm list | awk '{print $1}' | xargs -I {} qm shutdown {}
        # Esperar que les màquines es tanquin
        sleep 60
        # Reiniciar el servidor Proxmox
        reboot
    fi
    
    # Esperar 60 segons abans de fer el següent ping
    sleep 60
done