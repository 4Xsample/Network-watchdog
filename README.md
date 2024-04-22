|               |               |               |               |               |               |
|:-------------:|:-------------:|:-------------:|-------------:|-------------:|-------------:|
| ![Hack the planet](https://img.shields.io/badge/Hack-The%20Planet-orange) | [![Discord](https://img.shields.io/discord/667340023829626920?logo=discord)](https://discord.gg/ahVq54p) | [![Twitter](https://img.shields.io/twitter/follow/4xsample?style=social&logo=twitter)](https://twitter.com/4xsample/follow?screen_name=shields_io) | [![@4Xsample@mastodon.social](https://img.shields.io/badge/Mastodon-@4Xsample-blueviolet?style=for-the-badge&logo=mastodon)](https://mastodon.social/@4Xsample) | [![4Xsample](https://img.shields.io/badge/Twitch-4Xsample-6441A4?style=for-the-badge&logo=twitch)](https://twitch.tv/4Xsample) | [![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate/?hosted_button_id=EFVMSRHVBNJP4) |

# Network Watchdog per a Proxmox
### (De fet serveix per la majoria de màquines linux)

Aquest és un petit projecte que he creat per gestionar un problema recurrent que tenim amb un servidor Proxmox. De tant en tant, el servidor perd connexió a la xarxa i, per no haver d'anar físicament a reiniciar la màquina, he escrit aquest script que fa el treball per mi.

## Què fa exactament?

El script `network_watchdog.sh` executa un ping cada 60 segons a una IP específica de la xarxa. Si falla tres vegades seguides (és a dir, si no rep respostes de ping durant tres minuts consecutius), assumeix que hi ha un problema de xarxa. En aquest cas, apaga totes les màquines virtuals de manera segura i reinicia el servidor Proxmox.
```bash
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
```
Recorda canviar la IP de la linia 8 a la ip objectiu a la que vulguis apuntar.

## Com està configurat?

El script està configurat per ser executat com un servei de systemd. Això vol dir que s'inicia automàticament quan el sistema s'aixeca i continua corrent en segon pla.

### Fitxer de servei systemd

He creat un fitxer de servei systemd anomenat `network_monitor.service` que s'encarrega d'executar el script com a servei. Aquí tens el contingut del fitxer:

```ini
[Unit]
Description=Network Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/root/network_watchdog.sh

[Install]
WantedBy=multi-user.target
```

## Com s'utilitza?

Després de posar el script al seu lloc i crear el fitxer de servei, simplement s'ha d'habilitar i iniciar el servei amb les següents comandes:
```bash
sudo systemctl enable network_monitor.service
sudo systemctl start network_monitor.service
```

Si per alguna raó necessites aturar el servei (per exemple, si s'està reiniciant el servidor i no vols que segueixi reiniciant-se mentre investigues el problema) pots fer servir aquesta comanda:
```bash
sudo systemctl stop network_monitor.service
```

Però si et fa mandra haver de recordar la comanda o haver d'escriure amb pressa mentre el host està a punt de reiniciar-se pots configurar un alias com aquest:
```bash
alias prou='systemctl stop network_monitor.service'
```
i així al loguejar tant en local com per ssh només cal executar sudo prou i ja pararia el servei (o simplement dir prou si ets root però tots sabem que mai es treballa des de root oi que si?)
## Disclaimer: 
*Aquest codi s'ofereix tal com és i no es garanteix que funcioni correctament en totes les condicions. No em faig responsable dels danys que puguin resultar de l'ús d'aquesta informació. Utilitzeu-lo sota la vostra pròpia responsabilitat. Si teniu dubtes pregunteu i respondré al que pugui. Si voleu obrir proposar canvis podeu obrir fork i i voleu seguir-me, al panel del principi d'aquest readme podeu trobar links a les meves xarxes socials, Twitch i PayPal per si també voleu donar suport al meu treball.*