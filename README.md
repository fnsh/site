# FNSH site

Gluon site configuration to build firmware for Freie Netze Südhessen.

## Continous Integration

Firmware is built using GitHub actions as a CI. For more information, see the
`README.md` in the `.github` subdirectory.

### Usage

#### Trigger a Build

Builds are triggered by pushing a commit or tag to a branch. Both actions trigger a build cycle.
Artifacts are available after the CI finished and are available on a per-target basis.

#### Sign a Release

This repository contains a convenient script to sign a release created by this CI implementation.
The `sign-release.sh` script located in the `contrib` subfolder allows to obtain a signature for
a released firmware.

```sh
# Example: contrib/sign-release.sh 2.0.0 /path/to/private-key.ecdsakey
./contrib/sign-release.sh <release-version> <private-key-path>
```

### Releases

Releases are triggered by pushing a tag to GitHub.

The resulting firmware is versioned by the tag, while the first `-` in the tag name is replaced by a `~` character.

While Job artifacts expire eventually, artifacts from releases are preserved by creating a release on GitHub and uploading
build-outputs as well as the generated manifest to it.
