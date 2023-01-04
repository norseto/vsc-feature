#!/bin/bash
set -e

# The install.sh script is the installation entrypoint for any dev container 'features' in this repository. 
#
# The tooling will parse the devcontainer-features.json + user devcontainer, and write 
# any build-time arguments into a feature-set scoped "devcontainer-features.env"
# The author is free to source that file and use it however they would like.

function get_github_latest_tag {
  local desired=$1

  if [ "${desired}" != "latest" -a ! -z "${desired}" ] ; then
    echo ${desired}
    return
  fi

  local repo=$2;
  local default_tag=$3;
  local url="https://api.github.com/repos/${repo}/releases/latest"
  local tag=$(curl -sL ${url} | jq -re .tag_name 2>/dev/null)
  local stat=$?
  if [ ${stat} -eq 0 -a ! -z "${tag}" ] ; then
    echo ${tag}
  else
    echo ${default_tag}
  fi
}

architecture="$(uname -m)"
arch=${architecture}
case ${architecture} in
    x86_64)           architecture="amd64"; architecture2="x86_64"; arch="amd64";;
    aarch64 | armv8*) architecture="arm64"; architecture2="arm64";  arch="arm";;
    # aarch32 | armv7* | armvhf*) architecture="arm";;
    # i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

os="$(uname -s)"
case ${os} in
    Linux) os="linux";;
    # Darwin) os="darwin";;
    *) echo "(!) OS ${os} unsupported"; exit 1 ;;
esac

# AWS CLI
echo "Activating feature 'awscli'"

apt-get update
apt-get -y install --no-install-recommends python3-pip
apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*

pip3 install awscli

if [ ! -z ${EKSCTL} ] ; then
    echo "Activating feature 'eksctl'"
    VERSION=$(get_github_latest_tag "${EKSCTL}" weaveworks/eksctl v0.105.0)

    DLURL=https://github.com/weaveworks/eksctl/releases/download/${VERSION}/eksctl_$(echo ${os} | sed -e 's/l/L/')_${architecture}.tar.gz
    curl -L ${DLURL} | tar xz -C /tmp
    install /tmp/eksctl /usr/local/bin
    rm /tmp/eksctl
fi
