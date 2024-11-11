# vcenter-letsencrypt-auto-updater
Shell scripts to automatically keep LetsEncrypt certificates for vCenter Appliance up to date using Crontab

## Setup on VCenter Root user

### Pull Updater scripts
```
wget 'https://raw.githubusercontent.com/emryl/vcenter-letsencrypt-auto-updater/main/auto-updater.sh' -O auto-updater.sh
chmod 755 ./auto-updater.sh
wget 'https://raw.githubusercontent.com/emryl/vcenter-letsencrypt-auto-updater/main/update.conf' -O update.conf
sed -i "s/^cat/#cat/" auto-updater.sh
mkdir /root/.acme.sh
```

### Setup update.conf with login details

```
echo "CERTNAME=vcenter-hostname.yourdomain.yoursuffix
ADMINACCOUNT='Administrator@yourdomain.yoursuffix'
ADMINPASS='UPDATE PASSWORD HERE'" > /root/.acme.sh/update.conf
```

### Install acme

```
wget -O - https://get.acme.sh | sh
```

### Setup your credentials for DNS (AWS example)

```
mkdir .aws
echo "export AWS_ACCESS_KEY_ID=myaccess_key
export AWS_SECRET_ACCESS_KEY=mysecret_key" > .aws/credentials
. .aws/credentials
```

### Attempt initial certificate generation
```
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue --dns dns_aws -d vcenter-hostname.yourdomain.yoursuffix --server letsencrypt -k 4096
```

### Execute the auto-updater!
```
./auto-updater.sh
```

## If you want to have it updated regularly, setup this in root's crontab
```
40 3 * * sun /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null
15 3 * * sun /root/auto-updater.sh
```
