#!/bin/bash
set -e

# The install.sh script is the installation entrypoint for any dev container 'features' in this repository. 
#
# The tooling will parse the devcontainer-features.json + user devcontainer, and write 
# any build-time arguments into a feature-set scoped "devcontainer-features.env"
# The author is free to source that file and use it however they would like.
set -a
. ./devcontainer-features.env
set +a

architecture="$(uname -m)"
arch=${architecture}
case ${architecture} in
    x86_64) architecture="amd64"; architecture2="x86_64"; arch="amd64";;
    aarch64 | armv8*) architecture="arm64"; architecture2="arm64"; arch="arm";;
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

if [ ! -z ${_BUILD_ARG_KUBERNETES} ]; then
    # Skaffold
    if [ "xnone" != "x${_BUILD_ARG_KUBERNETES_SKAFFOLD}" ]; then
        echo "Activating feature 'skaffold'"

        VERSION=${_BUILD_ARG_KUBERNETES_SKAFFOLD:-latest}

        curl -sLo /tmp/skaffold https://storage.googleapis.com/skaffold/releases/${VERSION}/skaffold-${os}-${architecture}
        install /tmp/skaffold /usr/local/bin && rm -f /tmp/skaffold
    fi

    # K3d
    if [ "xnone" != "x${_BUILD_ARG_KUBERNETES_K3D}" ]; then
        echo "Activating feature 'k3d'"

        VERSION=${_BUILD_ARG_KUBERNETES_K3D:-latest}

        curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=${K3D_VERSION} bash
    fi

    # Kustomize
    if [ "xnone" != "x${_BUILD_ARG_KUBERNETES_KUSTOMIZE}" ]; then
        echo "Activating feature 'kustomize'"

        # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>
        VERSION=${_BUILD_ARG_KUBERNETES_KUSTOMIZE:-latest}
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
    if [ "xnone" != "x${_BUILD_ARG_KUBERNETES_ISTIOCTL}" ]; then
        echo "Activating feature 'istioctl'"

        # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>
        VERSION=${_BUILD_ARG_KUBERNETES_ISTIOCTL:-latest}
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
    if [ "xnone" != "x${_BUILD_ARG_KUBERNETES_KREW}" ]; then
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
fi

# Container-Structure-Test
if [ ! -z ${_BUILD_ARG_CONTAINER_STRUCTURE_TEST} ]; then
    echo "Installing container-structure-test..."

    curl -o /tmp/container-structure-test https://storage.googleapis.com/container-structure-test/latest/container-structure-test-${os}-${architecture}
    install /tmp/container-structure-test /usr/local/bin
    rm -f /tmp/container-structure-test
fi

# Gomplate
if [ ! -z ${_BUILD_ARG_GOMPLATE} ]; then
    echo "Activating feature 'gomplate'"

    VERSION=${_BUILD_ARG_GOMPLATE_VERSION:-v3.10.0}

    curl -vLo gomplate https://github.com/hairyhenderson/gomplate/releases/download/${VERSION}/gomplate_${os}-amd64-slim
    install gomplate /usr/local/bin
    rm gomplate
fi

# Python pip3
if [ ! -z ${_BUILD_ARG_PYTHON_PIP3} ]; then
    echo "Activating feature 'python-pip3'"
    apt-get update
    apt-get -y install --no-install-recommends python3-pip
    apt-get autoremove -y
    apt-get clean -y
    rm -rf /var/lib/apt/lists/*
fi

# AWS CLI
if [ ! -z ${_BUILD_ARG_AWSCLI} ]; then
    echo "Activating feature 'awscli'"

    pip3 install awscli

    if [ ! -z ${_BUILD_ARG_AWSCLI_EKSCTL} ] ; then
        echo "Activating feature 'eksctl'"
        VERSION=${_BUILD_ARG_AWSCLI_EKSCTL:-latest}
        DLURL=https://github.com/weaveworks/eksctl/releases/download/${VERSION}/eksctl_$(echo ${os} | sed -e 's/l/L/')_${architecture}.tar.gz
        if [ "xlatest" = "x${VERSION}" ] ; then
            DLURL=https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(echo ${os} | sed -e 's/l/L/')_${architecture}.tar.gz
        fi
        curl -L ${DLURL} | tar xz -C /tmp
        install /tmp/eksctl /usr/local/bin
        rm /tmp/eksctl
    fi
fi

# Protocolbuffer Compiler
if [ ! -z ${_BUILD_ARG_PROTOC} ]; then
    echo "Activating feature 'protobuf-compiler'"

    apt-get update
    apt-get -y install --no-install-recommends protobuf-compiler

    if [ "xtrue" = "x${_BUILD_ARG_PROTOC_GOLANG}" ]; then
        echo "Installing golang gRPC..."

        go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
        go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
        go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.5.0
        go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.5.0
    fi

    if [ "xtrue" = "x${_BUILD_ARG_PROTOC_PYTHON}" ]; then
        echo "Installing python gRPC..."

        python3 -m pip install grpcio
        python3 -m pip install grpcio-tools
    fi

    apt-get autoremove -y
    apt-get clean -y
    rm -rf /var/lib/apt/lists/*
fi

# Envoy Proxy
if [ ! -z ${_BUILD_ARG_ENVOY} ]; then
    echo "Activating feature 'envoy proxy'"
    cp -pr ./envoy /usr/local/envoy
fi

# Waypoint
if [ ! -z ${_BUILD_ARG_WAYPOINT} ]; then
    echo "Activating feature 'Waypoint'"

    VERSION=${_BUILD_ARG_WAYPOINT_VERSION:-0.8.1}

    curl -Lo /tmp/waypoint.zip https://releases.hashicorp.com/waypoint/${VERSION}/waypoint_${VERSION}_${os}_amd64.zip
    (cd /tmp; unzip waypoint.zip)
    install /tmp/waypoint /usr/local/bin
    rm -f /tmp/waypoint /tmp/waypoint.zip
fi

# ko
if [ ! -z ${_BUILD_ARG_KO} ]; then
    echo "Activating feature 'ko'"

    VERSION=${_BUILD_ARG_KO_VERSION:-0.11.2}

    curl -L https://github.com/google/ko/releases/download/v${VERSION}/ko_${VERSION}_${os}_${architecture2}.tar.gz | tar xzf - ko
    install ko /usr/local/bin
    rm -f ko
fi
