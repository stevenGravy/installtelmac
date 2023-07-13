#!/bin/bash
enterprise=true
while getopts p:v:e: flag
do
    case "${flag}" in
        p) proxy=${OPTARG};;
        v) version=${OPTARG};;
        e) enterprise=${OPTARG};;
    esac
done

if [ "$enterprise" = "true" ]; then
   entsegment=-ent
fi

if [ "$proxy" != "" ]; then
  echo "Proxy is $proxy"
  PROXY_VERSION=$(curl https://${proxy}/webapi/find | jq '.server_version')
  # remove double quotes
  PROXY_VERSION=${PROXY_VERSION//\"}
  version=${PROXY_VERSION}
  echo "Installing to match $proxy version $PROXY_VERSION"
elif [ "$version" != "" ]; then
  echo "Installing version $version enterprise: $enterprise"
else 
  echo "installtelmac.sh provides for installing the Teleportt and tsh packages "
  echo "automatically in order so the signed tsh is done after Teleport. Pkg"
  echo "file signatures are confimed prior to installation."
  echo " "
  echo "usage: installtelmac.sh [-p proxy.example.com] [-v 13.2.1] [-e true|false]"
  echo  "Install the teleport and tsh version to match the proxy or"
  echo "   match to a specific version. "
  echo " -p Teleport proxy"
  echo " -v Teleport version to install"
  echo " -e Enterprise version to install"
  exit 1
fi


echo "Getting signature from https://get.gravitational.com/teleport$entsegment-$version.pkg.sha256"
SIGNATURE=$(curl https://get.gravitational.com/teleport$entsegment-$version.pkg.sha256)
# Download Teleport pkg
wget https://cdn.teleport.dev/teleport$entsegment-$version.pkg
FILE_SIG=$(shasum -a 256 teleport$entsegment-$version.pkg)

if [ "$SIGNATURE" != "$FILE_SIG" ]
then
  echo "Mismatch in signatures for teleport"
  echo "Signature: $SIGNATURE"
  echo "File sig:  $FILE_SIG"
  exit 0
fi
echo "Signature confirmed"

echo "Install Teleport $version"
sudo installer -pkg teleport$entsegment-$version.pkg -target /

teleport version

echo "Getting signature from https://get.gravitational.com/tsh-$version.pkg.sha256"
SIGNATURE=$(curl https://get.gravitational.com/tsh-$version.pkg.sha256)
# Download Teleport pkg
wget https://cdn.teleport.dev/tsh-$version.pkg
FILE_SIG=$(shasum -a 256 tsh-$version.pkg)

if [ "$SIGNATURE" != "$FILE_SIG" ]
then
  echo "Mismatch in signatures for teleport"
  echo "Signature: $SIGNATURE"
  echo "File sig:  $FILE_SIG"
  exit 0
fi
echo "Signature confirmed"

echo "Install Teleport tsh $version"
sudo installer -pkg tsh-$version.pkg -target /

tsh version
echo "Confirm Touch ID enabled"
tsh touchid diag

echo " "
echo "Successful install. Confirm removing packages"
rm -i teleport$entsegment-$version.pkg
rm -i  tsh-$version.pkg


