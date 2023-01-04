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
- kpt - Set "latest" or "none". Default is "none" (v0.2.1)

## gomplate
Gomplate engine.
### Options
- version - Set version to install. Default is "latest"

## python-pip3
Python pip3
### Options
(None)

## awscli
AWS CLI installed with pip3
### Options
- eksctl - Set "latest" or eksctl version like "v0.92.0". Default is "latest"

## protoc
Protobuf Compiler with some language options.
### Options
- golang - If true, will install protoc-gen-go@v1.26 and so on. Default is false.
- python - If true, will install grpcio, grpcio-tools. Default is false.

## container-structure-test
[Container Structure Test](https://github.com/GoogleContainerTools/container-structure-test)
### Options
(None)

## Envoy
Scripts for [Envoy Proxy](https://www.envoyproxy.io/) in /usr/local/envoy
### Options
(None)

## Waypoint
[Waypoint](https://www.waypointproject.io/)
### Options
- version - Version to install e.g. "0.8.1"

## ko
[ko: Easy Go Containers](https://github.com/google/ko)
### Options
- version - Set version to install. Default is "latest"

## terraform-tools (v0.1.8)
Some tools not installed with official terraform feature.
### Options
- tfmigrate - Set version of [tfmigrate](https://github.com/minamijoyo/tfmigrate) to install. Default is "latest"
- tfdocs - Set version of [terraform-docs](https://github.com/terraform-docs/terraform-docs) to install. Default is "latest"

## terraform-diagram (v0.1.9)
Terraform diagram with python. Installs, diagrams python module, graphviz, xdg-utils and VS Code plugin. Requires pip3
### Options
(None)

## terraformer (v0.1.10)
Install [terraformer](https://github.com/GoogleCloudPlatform/terraformer).

### Options
- version - Set version to install. Default is "latest"
- provider - Provider to use. Default is "all"

---
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
