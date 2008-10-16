#!/bin/sh

echo "=> Installing PostgreSQL"

echo "=> Creating postgres user"
sudo dscl . -create /Users/postgres UniqueID 174
sudo dscl . -create /Users/postgres PrimaryGroupID 174
sudo dscl . -create /Users/postgres HomeDirectory /usr/local/pgsql
sudo dscl . -create /Users/postgres UserShell /usr/bin/false
sudo dscl . -create /Users/postgres RealName "PostgreSQL Administrator"
sudo dscl . -create /Users/postgres Password \*
dscl . -read /Users/postgres

echo "=> Creating postgres group"
sudo dscl . -create /Groups/postgres PrimaryGroupID 174
sudo dscl . -create /Groups/postgres Password \*
dscl . -read /Groups/postgres

echo "=> Creating the source folder if required"
mkdir -p ~/src
cd ~/src

echo "=> Downloading"
curl -O http://ftp2.au.postgresql.org/pub/postgresql//source/v8.2.6/postgresql-8.2.6.tar.gz

echo "=> Extracting"
tar xzvf postgresql-8.2.6.tar.gz
cd postgresql-8.2.6

echo "=> Configuring"
CC=gcc CFLAGS="-O3 -fno-omit-frame-pointer" CXX=gcc \
CXXFLAGS="-O3 -fno-omit-frame-pointer -felide-constructors \
-fno-exceptions -fno-rtti" \
./configure --with-bonjour

echo "=> Compiling"
make
echo "=> Installing"
sudo make install

echo "=> Creating initial database structure"
sudo mkdir /usr/local/pgsql/data
sudo chown postgres:postgres /usr/local/pgsql/data
sudo -u postgres /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

echo "=> Creating launchd item"
cat > /tmp/com.pgsql.pgsqld.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.postgresql.dbms</string>
    <key>UserName</key>
    <string>postgres</string>
    <key>GroupName</key>
    <string>postgres</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/pgsql/bin/postmaster</string>
      <string>-D</string>
      <string>/usr/local/pgsql/data</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
		<key>StandardErrorPath</key>
		<string>/usr/local/pgsql/logs/postgresql.log</string>
</dict>
</plist>
EOF

sudo mv /tmp/com.pgsql.pgsqld.plist /Library/LaunchDaemons
sudo chown root /Library/LaunchDaemons/com.pgsql.pgsqld.plist

echo "=> Starting PostgreSQL"
sudo launchctl load -w /Library/LaunchDaemons/com.pgsql.pgsqld.plist

echo "=> Building the C Bindings for Ruby"
sudo env ARCHFLAGS="-arch i386" gem install postgres

echo "=> Creating PostgreSQL user $USER and my_test_db"
createuser --superuser $USER -U postgres
createdb $USER

echo "=> Done"


# To undo what this script does use the following commands
# sudo gem uninstall postgres
# sudo launchctl stop com.pgsql.pgsqld
# sudo rm /Library/LaunchDaemons/com.pgsql.pgsqld.plist
# sudo rm -rf /usr/local/pgsql
# sudo dscl . -delete /Groups/postgres
# sudo dscl . -delete /Users/postgres

# Acknowledgements
# http://www.working-software.com/node/30
# http://hivelogic.com/articles/installing-mysql-on-mac-os-x/