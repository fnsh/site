# Workflows

## build

Build and release Firmware.

### Secrets

#### GHA_FNSH_BUILD_DEPLOY_SSH_KEY

SSH private key required for deployment on the firmware download server.

#### GHA_FNSH_BUILD_ECDSA_KEY_{branch}

Private ECDSA key for signing the manifest for a given `branch`.

At FFDA, we currently define the following keys:

 * GHA_FNSH_BUILD_ECDSA_KEY_TESTING


## check-build-info

Validate the `build-info.json` is valid JSON.
