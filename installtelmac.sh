#!/bin/bash
# See README at https://github.com/stevenGravy/installtelmac
enterprise=true
signatureurl=https://cdn.teleport.dev
contenturl=https://cdn.teleport.dev
deletewithoutconfirming=true
checksum=true
installtshpkg=true

# function to check whether a named program exists
check_exists() {
    NAME=$1
    if type "${NAME}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# check for jq is moved down to proxy option. not needed in most flows
for BINARY in curl shasum ; do
    if ! check_exists ${BINARY}; then
        echo "${BINARY} must be installed, it was not found"
        exit 1
    fi
done

while getopts p:v:e:d:c:i: flag
do
    case "${flag}" in
        p) proxy=${OPTARG};;
        v) version=${OPTARG};;
        e) enterprise=${OPTARG};;
        d) deletewithoutconfirming=${OPTARG};;
        c) checksum=${OPTARG};;
        i) installtshpkg=${OPTARG};;
    esac
done

if [ "$enterprise" = "true" ]; then
   entsegment=-ent
fi

if [ "$proxy" != "" ]; then
  for BINARY in  jq ; do
    if ! check_exists ${BINARY}; then
        echo "${BINARY} must be installed, it was not found"
        exit 1
    fi
  done
  echo "Proxy is $proxy"
  PROXY_VERSION=$(curl --silent https://${proxy}/webapi/find | jq '.server_version')
  # remove double quotes
  PROXY_VERSION=${PROXY_VERSION//\"}
  version=${PROXY_VERSION}
  echo "Installing to match $proxy version $PROXY_VERSION enterprise version: $enterprise"
elif [ "$version" != "" ]; then
  echo "Installing version $version enterprise version: $enterprise"
else 
  echo "installtelmac.sh provides for installing the Teleportt and tsh packages "
  echo "automatically in order so the signed tsh is done after Teleport. Pkg"
  echo "file signatures are confimed prior to installation."
  echo " "
  echo "usage: installtelmac.sh [-p proxy.example.com] [-v 13.2.1] [-e true|false] [-d true|false]"
  echo  "Install the Teleport version to match the proxy or"
  echo "   match to a specific version. "
  echo " -p Teleport proxy"
  echo " -v Teleport version to install"
  echo " -e Use enterprise version to install (default: true)"
  echo " -d Delete pkg files without confirming (default: true)"
  echo " -c Checksum files before installing (default: true)"
  echo " -i Install tsh pkg (default: true for <v17 versions)"
  echo " "
  echo "Note: the install of .pkg files requires sudo rights"
  exit 1
fi

# Check if this is >=v17. If so then don't install tsh package

versionNumber=$(echo ${version}  |cut -d '.' -f 1)

if (( $versionNumber >= 17 )); then
  installtshpkg=false
fi
  


# Verify files exist

checkurl () {

HTTPCODE=$(curl --silent -I $1 | grep -E "^HTTP" | awk -F " " '{print $2}')
if [ "$HTTPCODE" != "200" ]
then 
  echo "$1 unavailable. $2. Check version"
  exit 1
fi
echo "Confirmed URL $1. $2."

}

# These are different since they won't return headers
checksigurl () {

SIG=$(curl --silent $1)
if [[ "$SIG" == "" ]]
then 
  echo "$1 unavailable. $2. Check version"
  exit 1
fi
echo "Confirmed $1. $2."

}


echo "Validating files for install"
if [ "$checksum" == "true" ]
then
  checksigurl "$signatureurl/teleport$entsegment-$version.pkg.sha256" "Used for confirming Teleport checksum"
  if [ "$installtshpkg" == "true" ] 
  then
    checksigurl "$signatureurl/tsh-$version.pkg.sha256" "Used for confirming tsh checksum"
  fi
else
  echo "Skipping confirming checksum"
fi
checkurl "$contenturl/teleport$entsegment-$version.pkg" "Teleport package"
if [ "$installtshpkg" == "true" ]
then
  checkurl "$contenturl/tsh-$version.pkg" "tsh install package"
fi




if [ "$checksum" == "true" ]
then
  echo -e "Getting signature from $signatureurl/teleport$entsegment-$version.pkg.sha256"
  SIGNATURE=$(curl --silent $signatureurl/teleport$entsegment-$version.pkg.sha256)
fi

# Download Teleport pkg
echo -e "Downloading Teleport pkg"
curl -O $contenturl/teleport$entsegment-$version.pkg

if [ "$checksum" == "true" ]
then
  FILE_SIG=$(shasum -a 256 teleport$entsegment-$version.pkg)
  if [ "$SIGNATURE" != "$FILE_SIG" ]
  then
    echo "Mismatch in signatures for teleport"
    echo "Signature: $SIGNATURE"
    echo "File sig:  $FILE_SIG"
    exit 0
  fi
  echo "Signature confirmed"
fi

echo "Install Teleport $version: sudo installer -pkg teleport$entsegment-$version.pkg -target /"
sudo installer -pkg teleport$entsegment-$version.pkg -target /

echo "Teleport version available:"
teleport version

if [ "$installtshpkg" == "true" ]
then
  if [ "$checksum" == "true" ]
  then
    echo "Getting signature from $signatureurl/tsh-$version.pkg.sha256"
    SIGNATURE=$(curl $signatureurl/tsh-$version.pkg.sha256)
  fi

  # Download tsh pkg
  echo -e "Downloading Teleport tsh pkg"
  curl -O $contenturl/tsh-$version.pkg

  if [ "$checksum" == "true" ]
  then
    FILE_SIG=$(shasum -a 256 tsh-$version.pkg)
    if [ "$SIGNATURE" != "$FILE_SIG" ]
    then
      echo "Mismatch in signatures for teleport"
      echo "Signature: $SIGNATURE"
      echo "File sig:  $FILE_SIG"
      exit 0
    fi
    echo "Signature confirmed"
  fi

  echo "Install Teleport tsh $version: sudo installer -pkg tsh-$version.pkg -target /"
  sudo installer -pkg tsh-$version.pkg -target /

fi
echo " "
echo "Version confirmation"
tsh version
echo " "
echo "Confirm Touch ID enabled"
tsh touchid diag

echo " "
if [ "$deletewithoutconfirming" = "false" ]; then
  echo "Successful install. Confirm removing packages"
  rm -i teleport$entsegment-$version.pkg
  if [ "$installtshpkg" == "true" ]; then
    rm -i tsh-$version.pkg
  fi
else 
  echo "Successful install. Removing pkg files"
  rm teleport$entsegment-$version.pkg
  if [ "$installtshpkg" == "true" ]; then
    rm tsh-$version.pkg
  fi
fi


echo "Install complete of version: $version!"
