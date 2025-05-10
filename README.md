
# Cluster Configuration Git Repository

This repository provides Infrastructure as Code sources in the `apps` directory
suitable for use in OpenShift-GitOps (ArgoCD). Each app may be used by cluster
configurations as specified in the `clusters` directory.

The model is that individual clusters defined in the `clusters` directories pull
in apps defined in the `apps` directories. The cluster configurations provide
cluster-specific parameters for the apps (e.g. helm values or kustomize overlays).

## Cluster/<app-name> Helm Argo Apps

For the simplest helm app values, put the `values.yaml` file in the
`clusters/<cluster-name>/<app-name>/ directory. An argo app using the <app-name>
directory name will be created automatically and will show up in the dashboard.

You can preview the generated configurations by running:

    helm template -f ./clusters/<cluster-name>/<app-name>/values.yaml ./apps/<app-name> | less

You can manually apply the configurations to a cluster by running:

    helm template -f ./clusters/<cluster-name>/<app-name>values.yaml ./apps/<app-name> | oc create -f -

This use-case is implemented in the `apps/app-of-apps/helm-apps.yaml` manifest.

You can 