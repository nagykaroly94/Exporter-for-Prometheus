#!/bin/bash

npassword_hash=$(python3 jelszo.py)
echo $npassword_hash

echo -n "Kérlek add meg a MySQL root jelszavát:  "
read -s password
echo

echo "A jelszót sikeresen beolvastuk és tároltuk a futtatás idejére"

npassword=$(cat /tmp/.python.pwd)

sudo mysql \
  --user="root" \
  --password="$password" \
  --execute="CREATE USER 'mysqld_exporter'@'localhost' IDENTIFIED BY '$npassword';" \
  --execute="GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';" \
  --execute="FLUSH PRIVILEGES;"

LOGFILE="/usr/local/bin/exporters_telepites.log"
exec > >(tee -i ${LOGFILE})
exec 2>&1

echo "A telepítés elkezdődött $(date)"

error_exit() {
    echo "Hiba a(z) $1 sorban"
    exit 1
    sudo rm -r /tmp/.python.pwd
}

trap 'error_exit $LINENO' ERR

sudo cp apache_exporter mysqld_exporter node_exporter endlessh-go /usr/local/bin
sudo cp apache_exporter.service mysqld_exporter.service node_exporter.service endlessh-go.service /etc/systemd/system

sudo echo "[client]" > /usr/local/bin/.my.cnf
sudo echo "user=mysqld_exporter" >> /usr/local/bin/.my.cnf
sudo echo "password=${npassword}" >> /usr/local/bin/.my.cnf

sudo chmod 600 /usr/local/bin/.my.cnf

add_chown_user() {
    local user=$1
    local binary=$2

    if ! getent group "$user" >/dev/null 2>&1; then
        sudo addgroup --system "$user"
    else
        echo "A(z) $user csoport már létezik."
    fi

    if ! id -u "$user" >/dev/null 2>&1; then
        sudo adduser --system --ingroup "$user" --no-create-home --shell /sbin/nologin "$user"
    else
        echo "A felhasználó $user már létezik."
    fi

    sudo chown "$user:$user" "/usr/local/bin/$binary"
}

add_chown_user "node_exporter" "node_exporter"
add_chown_user "apache_exporter" "apache_exporter"
add_chown_user "mysqld_exporter" "mysqld_exporter"
add_chown_user "endlessh-go" "endlessh-go"

for mod in node_exporter apache_exporter mysqld_exporter endlessh-go; do
    sudo chmod 774 /usr/local/bin/"${mod}"
done


sudo systemctl daemon-reload
for service in node_exporter apache_exporter mysqld_exporter endlessh-go; do
    sudo systemctl enable "${service}.service"
    sudo systemctl start "${service}.service"
done

echo "A telepítés sikeresen befejeződött $(date)"
