
# Multi-Cluster GitOps Configuration Repository

This repository contains Infrastructure as Code (IaC) resources for managing
Kubernetes clusters using OpenShift GitOps (ArgoCD).

* Application configurations are found in the `/apps` directory.

* Cluster-specific customizations are defined in the `/clusters` directory.

Each cluster pulls in application definitions from `/apps`, while customizing
them via values or overlays in `/clusters`.

## Purpose

This is a starter repository to quickly bootstrap multi-cluster Kubernetes
infrastructure using GitOps principles. Careful customization is required for
your environment.

## Design Philosophy

### Prioritize Understanding

Developers spend the majority of their time trying to understand code. Reusing
consistent patterns and reducing unnecessary variation supports:

* Faster onboarding

* Fewer misunderstandings

* More reliable operations

This repository emphasizes convention over configuration to streamline
comprehension.

### Convention as Code

The folder structure defines ArgoCD Applications directly:

* `/apps/<app-name>`: shared app source

* `/clusters/<cluster-name>/<app-name>.yaml`: adds app to a cluster (creates argo app)

This leads to a predictable argo application naming convention:
`<cluster-name>---<app-name>`

This name appears in:

* The Git repository (/clusters/`<cluster-name>/<app-name>`)

* The ArgoCD dashboard (`<cluster-name>---<app-name>`)

* The cluster itself (Project/Namespace as `<app-name>`)

### Visibility into Configurations

Cluster configurations directly affect service availability. Therefore:

* App names should commonly align with the namespace/project names used on
  clusters.

* Config files should make the source of truth obvious.

This repo structure is designed to surface cluster configuration in a consistent
and simple pattern and avoid boilerplate configurations.

## Usage Patterns

### Simple App Deployment

To deploy an app to a cluster with no custom configuration:

1. Create an empty file:

    `/clusters/<cluster-name>/<app-name>.yaml`

2. The ApplicationSet controller will automatically create an ArgoCD App named:

    `<cluster-name>---<app-name>`

3. Where the ArgoCD App source will be this repo with path `/apps/<app-name>`.

This works because:

* The filename (without .yaml) must match the directory name under /apps/.

This reflects the Convention as Code principle.

### Helm-Based Applications

#### localHelmValues

To inline Helm values directly into the cluster app configuration file:

1. In `/clusters/<cluster-name>/<app-name>.yaml`, add:

        localHelmValues: true

        # helm values:
        someKey: someValue

2. Preview the rendered output:

        helm template -f ./clusters/<cluster-name>/<app-name>.yaml ./apps/<app-name> | less

This results in a single file with Helm values with ArgoCD configuration
overrides, providing a single app configuration file.

Optional: if separation is preferred or required, use the valuesFile method
below.

#### valuesFile Use Case

To define Helm values in a separate file:

1. In `/clusters/<cluster-name>/<app-name>.yaml`, specify:

        valuesFile: '/clusters/<cluster-name>/<app-name>/values.yaml'

2. Create the file `/clusters/<cluster-name>/<app-name>/values.yaml` with your
   Helm values.

3. Preview the rendered output:

        helm template -f ./clusters/<cluster-name>/<app-name>/values.yaml ./apps/<app-name> | less

## Implementation

The `/apps/app-of-apps/app-of-apps.yaml` ArgoCD ApplicationSet resource
implements the `/apps` and `/clusters` pattern used by this repository.

## Team Guidelines

Choosing GitOps conventions and tooling is a team responsibility. Use this repo
as a foundation, and evolve it through collaboration and operational feedback.

Simplicity is a goal—but too much simplicity can become ambiguity. Strive for
clarity. Make decisions intentionally.
