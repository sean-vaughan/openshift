
# External Secrets Custom Resources Sync

The is a short-term solution for generating custom resources from External
Secrets definitions, leveraging the [External Secrets Operator
(ESO)](https://external-secrets.io). ESO has an [implementation in code
review](https://github.com/external-secrets/external-secrets/pull/5470)
currently that should be used to replace this solution once released.

The requirements for this short-term solution are below.

# ExternalSecret definition requirements for auto-generating custom resources:

Add the label `generate-custom-resources: true` to ExternalSecrets that generate
secrets containing data elements with yaml manifests that should be
created/applied to the kubernetes API.

In the ExternalSecret secret template, define the manifest with the templated
secret value, as below. This would be the only manifest that will be in git and
does not contain the password hash.

    apiVersion: external-secrets.io/v1
    kind: ExternalSecret
    metadata:
      name: core-password-machineconfigs
      namespace: openshift-machine-config-operator
      labels:
        generate-custom-resources: true
    spec:
      refreshInterval: 1h
      secretStoreRef:
        kind: ClusterSecretStore
        name: vault-cert-auth
      target:
        name: core-password-machineconfigs
        template:
          engineVersion: v2
          data:
            machineconfig-worker.yaml: |
              apiVersion: machineconfiguration.openshift.io/v1
              kind: MachineConfig
              metadata:
                name: 99-set-core-password-worker
                labels:
                  machineconfiguration.openshift.io/role: worker
              spec:
                config:
                  ignition:
                    version: 3.2.0
                  passwd:
                    users:
                      - name: core
                        passwordHash: {{ .passwordHash }} # .passwordHash is replaced by the value in Vault
            machineconfig-master.yaml: |
              apiVersion: machineconfiguration.openshift.io/v1
              kind: MachineConfig
              metadata:
                name: 99-set-core-password-master
                labels:
                  machineconfiguration.openshift.io/role: master
              spec:
                config:
                  ignition:
                    version: 3.2.0
                  passwd:
                    users:
                      - name: core
                        passwordHash: {{ .passwordHash }} # .passwordHash is replaced by the value in Vault
      data:
        - secretKey: passwordHash
          remoteRef:
            key: secret/data/core/password
            property: passwordHash

Given the ExternalSecret definition, ESO would generate a secret named
core-password-machineconfigs, in the openshift-machine-config-operator namespace
which would look like below. Note that `passwordHash` would have the hydrated
value from Vault. (The `stringData` secret is shown below to display the
non-base64 encoded values, but these would be base64 encoded in the API):

    kind: Secret
    apiVersion: v1
    metadata:
      name: core-password-machineconfigs
      namespace: openshift-machine-config-operator
    stringData:
      machineconfig-worker.yaml: |
        apiVersion: machineconfiguration.openshift.io/v1
        kind: MachineConfig
        metadata:
          name: 99-set-core-password-worker
          labels:
            machineconfiguration.openshift.io/role: worker
        spec:
          config:
            ignition:
              version: 3.2.0
            passwd:
              users:
                - name: core
                  passwordHash: "$6$8Yy3HkZb$Xik93x3...MxeiTy7Xz1"
      machineconfig-master.yaml: |
        apiVersion: machineconfiguration.openshift.io/v1
        kind: MachineConfig
        metadata:
          name: 99-set-core-password-worker
          labels:
            machineconfiguration.openshift.io/role: master
        spec:
          config:
            ignition:
              version: 3.2.0
            passwd:
              users:
                - name: core
                  passwordHash: "$6$8Yy3HkZb$Xik93x3...MxeiTy7Xz1"


Then the CronJob script would take these generated secrets, and apply each data
element (e.g. `machineconfig-worker.yaml` and `machineconfig-worker.yaml` data
elements) to the kubernetes API, analogous to the commands below:

    cat << EOF | oc apply -f -
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      name: 99-set-core-password-worker
      labels:
        machineconfiguration.openshift.io/role: worker
    spec:
      config:
        ignition:
          version: 3.2.0
        passwd:
          users:
            - name: core
              passwordHash: "$6$8Yy3HkZb$Xik93x3...MxeiTy7Xz1"
    EOF

    cat <<EOF | oc apply -f
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      name: 99-set-core-password-master
      labels:
        machineconfiguration.openshift.io/role: master
    spec:
      config:
        ignition:
          version: 3.2.0
        passwd:
          users:
            - name: core
              passwordHash: "$6$8Yy3HkZb$Xik93x3...MxeiTy7Xz1"
    EOF

Thus the labeled ExternalSecret would generate the desired manifests.

# CronJob script functionality definition:

1. Every 5 minutes, or at a different configured interval, the CronJob script
   would run.
2. For every ExternalSecret kubernetes resource, in every namespace, that has a
   label `generate-custom-resources: true`, the following procedure would run:
    1. Identify the generated kubernetes secret the ExternalSecret created or
       updated. (Skip the remaining steps for this ExternalSecret and log a
       message if the secret hasn't been created.)
    2. For every data element in the generated kubernetes secret (e.g.
       `machineconfig-worker.yaml` and `machineconfig-master.yaml` above), apply
       the data element value to the kubernetes API. Log any errors.
3. Exit.

# Security:

The CronJob would have a service account bound to a role that only allows the
script to read ExternalSecrets and kubernetes secrets, and read and write (get,
list, watch, create, update, patch) specific resource types. For the current
core user password hash use-case, writing would only be allowed for `kind:
MachineConfig` resources.
