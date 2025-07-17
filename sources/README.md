
# apps Directory

The `apps` directory contains kubernetes apps in the form usable by
OpenShift-GitOps (ArgoCD). Specifically, each subdirectory should strictly be
usable as the source for an ArgoApp resource, so, one of: a simple directory
with manifests, Kustomize configurations, or a helm chart.
