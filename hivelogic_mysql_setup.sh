#!/bin/sh

echo "=> Installing MySQL"

echo "=> Creating the source folder"
mkdir -p ~/src
cd ~/src

echo "=> Downloading"
curl -O http://mysql.mirrors.ilisys.com.au/Downloads/MySQL-5.0/mysql-5.0.51b.tar.gz

echo "=> Extracting"
tar xzvf mysql-5.0.51b.tar.gz
cd mysql-5.0.51b

echo "=> Configuring"
CC=gcc CFLAGS="-O3 -fno-omit-frame-pointer" CXX=gcc \
CXXFLAGS="-O3 -fno-omit-frame-pointer -felide-constructors \
-fno-exceptions -fno-rtti" \
./configure --prefix=/usr/local/mysql \
--with-extra-charsets=complex --enable-thread-safe-client \
--enable-local-infile --disable-shared

echo "=> Compiling"
make
echo "=> Installing"
sudo make install

echo "=> Creating default databases"
cd /usr/local/mysql
sudo ./bin/mysql_install_db --user=mysql
echo "=> Setting permissions"
sudo chown -R mysql ./var

echo "=> Creating launchd item"
cat > /tmp/com.mysql.mysqld.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>com.mysql.mysqld</string>
	<key>Program</key>
	<string>/usr/local/mysql/bin/mysqld_safe</string>
	<key>RunAtLoad</key>
	<true/>
	<key>UserName</key>
	<string>mysql</string>
	<key>WorkingDirectory</key>
	<string>/usr/local/mysql</string>
</dict>
</plist>
EOF

sudo mv /tmp/com.mysql.mysqld.plist /Library/LaunchDaemons
sudo chown root /Library/LaunchDaemons/com.mysql.mysqld.plist

echo "=> Starting MySQL"
sudo launchctl load -w /Library/LaunchDaemons/com.mysql.mysqld.plist

echo "=> Building the C Bindings for Ruby"
sudo env ARCHFLAGS="-arch i386" gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config

echo "=> Done"
