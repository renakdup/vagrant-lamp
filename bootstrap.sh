#!/usr/bin/env bash

# Variables
IP=""
MYSQL_PASS="toor"

# Set timezone to Belgrade/Serbia -> you will probably need to change this
sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Belgrade /etc/localtime

sudo apt-get update >> /vagrant/build.log 2>&1

echo "-- Installing debianconf --"
sudo apt-get install -y debconf-utils >> /vagrant/build.log 2>&1

echo "-- Installing dirmngr --"
sudo apt-get install dirmngr >> /vagrant/build.log 2>&1

echo "-- Installing unzip --"
sudo apt-get install -y unzip >> /vagrant/build.log 2>&1

echo "-- Installing aptitude --"
sudo apt-get -y install aptitude >> /vagrant/build.log 2>&1

echo "-- Updating package lists --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

#echo "-- Updating system --"
#//sudo aptitude safe-upgrade -y >> /vagrant/build.log 2>&1

echo "-- Uncommenting alias for ll --"
sed -i "s/#alias ll='.*'/alias ll='ls -al'/g" /home/vagrant/.bashrc

echo "-- Installing curl --"
sudo aptitude install -y curl >> /vagrant/build.log 2>&1

echo "-- Installing apt-transport-https --"
sudo aptitude install -y apt-transport-https >> /vagrant/build.log 2>&1

echo "-- Adding GPG key for sury repo --"
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >> /vagrant/build.log 2>&1

echo "-- Adding PHP 7 packages repo --"
echo 'deb https://packages.sury.org/php/ stretch main' | sudo tee -a /etc/apt/sources.list >> /vagrant/build.log 2>&1

echo "-- Updating package lists again after adding sury --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

echo "-- Installing Apache --"
sudo aptitude install -y apache2 >> /vagrant/build.log 2>&1

echo "-- Enabling mod rewrite --"
sudo a2enmod rewrite >> /vagrant/build.log 2>&1

echo "-- Configuring Apache --"
sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo "-- Adding MySQL GPG key --"
wget -O /tmp/RPM-GPG-KEY-mysql https://repo.mysql.com/RPM-GPG-KEY-mysql >> /vagrant/build.log 2>&1
sudo apt-key add /tmp/RPM-GPG-KEY-mysql >> /vagrant/build.log 2>&1

echo "-- Adding MySQL repo --"
echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-5.7" | sudo tee /etc/apt/sources.list.d/mysql.list >> /vagrant/build.log 2>&1

echo "-- Updating package lists after adding MySQL repo --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS"

echo "-- Installing MySQL server --"
sudo aptitude install -y mysql-server >> /vagrant/build.log 2>&1

echo "-- Creating alias for quick access to the MySQL (just type: db) --"
echo "alias db='mysql -u root -p$MYSQL_PASS'" >> /home/vagrant/.bashrc

echo "-- Installing PHP stuff --"
sudo aptitude install -y libapache2-mod-php7.3 php7.3 php7.3-pdo php7.3-mysql php7.3-mbstring php7.3-xml php7.3-intl php7.3-tokenizer php7.3-gd php7.3-imagick php7.3-curl php7.3-zip php7.3-bcmath >> /vagrant/build.log 2>&1

echo "-- Installing Xdebug --"
sudo aptitude install -y php-xdebug >> /vagrant/build.log 2>&1

echo "-- Installing libpng-dev (required for some node package) --"
sudo aptitude install -y libpng-dev >> /vagrant/build.log 2>&1

echo "-- Configuring xDebug (idekey = PHP_STORM) --"
sudo tee -a /etc/php/7.3/mods-available/xdebug.ini << END
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9001
xdebug.idekey=PHP_STORM
END

echo "-- Restarting Apache --"
sudo /etc/init.d/apache2 restart >> /vagrant/build.log 2>&1

echo "-- Installing Git --"
sudo aptitude install -y git >> /vagrant/build.log 2>&1

echo "-- Installing Composer --"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer >> /vagrant/build.log 2>&1

echo "-- Installing node.js -->"
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - >> /vagrant/build.log 2>&1
sudo aptitude install -y nodejs >> /vagrant/build.log 2>&1

echo "-- Setting document root --"
if [ ! -L /var/www/html ]; then
    if [ ! -d /vagrant/source/public ]; then
        sudo mkdir -p /vagrant/source/public
    fi
    sudo rm -rf /var/www/html
    sudo ln -fs /vagrant/source/public /var/www/html
fi
if [ -d /vagrant/source/node_modules ]; then
    echo "-- Removing node_modules folder --"
    sudo rm -rf /vagrant/source/node_modules
fi
echo "-- Creating node_modules folder outside synced folder  --"
mkdir /home/vagrant/node_modules
echo "-- Linking node_modules folder  --"
sudo ln -fs /home/vagrant/node_modules /vagrant/source/node_modules
if [ -d /vagrant/source/vendor ]; then
    echo "-- Removing vendor folder --"
    sudo rm -rf /vagrant/source/vendor
fi