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

function get_filtered_github_latest_tag {
  local desired=$1

  if [ "${desired}" != "latest" -a ! -z "${desired}" ] ; then
    echo ${desired}
    return
  fi

  local repo=$2;
  local default_tag=$3;
  local url="https://api.github.com/repos/${repo}/releases"
  local tag=$(curl -sL ${url} | jq -re 'first(.[].tag_name | match("^[^/]+$") | .string)' 2>/dev/null)
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

# Skaffold
if [ "xnone" != "x${SKAFFOLD}" ]; then
    echo "Activating feature 'skaffold'"

    VERSION=${SKAFFOLD:-latest}

    curl -sLo /tmp/skaffold https://storage.googleapis.com/skaffold/releases/${VERSION}/skaffold-${os}-${architecture}
    install /tmp/skaffold /usr/local/bin && rm -f /tmp/skaffold
fi

# K3d
if [ "xnone" != "x${K3D}" ]; then
    echo "Activating feature 'k3d'"

    VERSION=${K3D:-latest}

    curl -sL https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=${K3D_VERSION} bash
fi

# Kustomize
if [ "xnone" != "x${KUSTOMIZE}" ]; then
    echo "Activating feature 'kustomize'"

    # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>
    VERSION=${KUSTOMIZE:-latest}
    if [ ${VERSION} = "latest" ] ; then
        VERSION=""
    fi

    curl -sLo /tmp/install_kustomize.sh "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
    # Add workaround for ARM Linux
    sed -i -e 's/arm64)/arm64|aarch64)/' /tmp/install_kustomize.sh
    chmod +x /tmp/install_kustomize.sh

    (
        cd /tmp &&
        ./install_kustomize.sh ${VERSION} &&
        install kustomize /usr/local/bin/ && rm -f kustomize /go/kustomize /tmp/install_kustomize.sh
    )
fi

# Istio CLI
if [ "xnone" != "x${ISTIOCTL}" ]; then
    echo "Activating feature 'istioctl'"

    # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>
    VERSION=${ISTIOCTL:-latest}
    if [ ${VERSION} = "latest" ] ; then
        VERSION=""
    fi

    (
        mkdir /tmp/istio &&
        cd /tmp/istio && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${VERSION} sh - &&
        install /tmp/istio/istio-*/bin/istioctl /usr/local/bin &&
        rm -rf /tmp/istio
    )
fi

# Krew Installer
if [ "xnone" != "x${KREW}" ]; then
    echo "Activating feature 'krew'"

    mkdir -p /usr/local/install/k8s
    cat <<EOF > /usr/local/install/k8s/krew.sh
#!/usr/bin/env bash
set -e
#--------------------------------------
# Krew
#--------------------------------------
if [ -z "\$(git config --global init.defaultBranch)" ] ; then
  git config --global init.defaultBranch main
fi

(
  set -x; cd "\$(mktemp -d)" &&
  OS="\$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="\$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-\${OS}_\${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/\${KREW}.tar.gz" &&
  tar zxvf "\${KREW}.tar.gz" &&
  ./"\${KREW}" install krew
)
echo 'export PATH="\${KREW_ROOT:-\$HOME/.krew}/bin:\$PATH"' >> \$HOME/.bashrc
PATH="\${HOME}/.krew/bin:\$PATH" kubectl krew install ns
PATH="\${HOME}/.krew/bin:\$PATH" kubectl krew install ctx
EOF
        chmod +x /usr/local/install/k8s/krew.sh
fi

# kpt
if [ "xnone" != "x${KPT}" ]; then
    echo "Activating feature 'kpt'"

    VERSION=${KPT:-latest}
    VERSION=$(get_filtered_github_latest_tag "${VERSION}" GoogleContainerTools/kpt v0.39.1 | sed -e 's/v//')

    curl -sLo kpt https://github.com/GoogleContainerTools/kpt/releases/download/v${VERSION}/kpt_${os}_${architecture}
    install kpt /usr/local/bin
    rm -f kpt
fi
