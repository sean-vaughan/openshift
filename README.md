
# Cluster Configuration Git Repository

This repository provides Infrastructure as Code sources in the `apps` directory
suitable for use in OpenShift-GitOps (ArgoCD). Each app may be used by cluster
configurations as specified in the `clusters` directory.

The model is that individual clusters defined in the `clusters` directories pull
in apps defined in the `apps` directories. The cluster configurations provide
cluster-specific parameters for the apps (e.g. helm values or kustomize overlays).

For helm charts, you can preview the generated configurations by running:

    helm template -f ./clusters/<cluster-name>/<app-name>.yaml ./apps/<app-name> | less

You can manually apply the configurations by running:

    helm template -f ./clusters/<cluster-name>/<app-name>.yaml ./apps/<app-name> | oc create -f -
