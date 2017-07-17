Auto switch between the most profitable coin.

It assumes that you have set up systemd for claymore on Ubuntu:
```
cat << EOF > /etc/systemd/system/claymore.service
[Unit]
Description=Claymore Etherenet Miner
After=syslog.target

[Service]
Type=simple
User=paulpas
PIDFile=/var/pid/claymore.pid
ExecStartPre=/bin/rm -f /var/run/claymore.pid
ExecStart=/opt/Claymore/start.bash
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable claymore.service
systemctl start claymore.service
```

On ethOS is requires that you have your claymore miner utilizing claymore.stub.conf

You will need to put this into your path
```
echo "PATH=$PATH:$HOME/git/scripts/scripts/whattomine" >> $HOME/.bashrc
```

Now setup in cron to check every hour and make a switch.
```
0 * * * * $HOME/git/scripts/scripts/whattomine/switchclaymore.sh
```
