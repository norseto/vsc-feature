> ⚠️ NOTE: This functionality is in PREVIEW. Please note it is subject to (heavy) modification!  

# Features In This Repo

## kubernetes
This is a kubernetes tools feature that contains some cli below.
### Options
- skaffold - Set version to install. Default is "latest"
- k3d - Set version to install. Default is "latest"
- kustomize - Set version to install. Default is "none"
- istioctl - Set version to install. Default is "none"
- krew - Set "latest" or "none". Default is "latest"

## gomplate
This is a gomplate engine.
### Options
- version - Set version to install. Default is "latest"

## python-pip3
Python pip3
### Options
(None)

## awscli
AWS CLI installed with pip3
### Options
(None)

## protoc
Protobuf Compiler with some language options.
### Options
- golang - If true, will install protoc-gen-go@v1.26 and so on. Default is false.
- python - If true, will install grpcio, grpcio-tools. Default is false.

## container-structure-test
[Container Structure Test](https://github.com/GoogleContainerTools/container-structure-test)
### Options
(None)

## Include these features in your project's devcontainer 

To include your feature in a project's devcontainer, provide the following `features` like so.

```jsonc
"image": "mcr.microsoft.com/vscode/devcontainers/base",
features: {
    "norseto/vsc-feature/kubernetes": {
        "kustomize": "latest"
    }
}
```

Providing no version implies the latest release's artifacts.  To supply a tag as a version, use the following notation.

```jsonc
features: {
    "norseto/vsc-feature/kubernetes@v0.1.0": {
        "kustomize": "latest"
    }
}
```
