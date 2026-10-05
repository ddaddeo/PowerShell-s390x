# PowerShell on Linux s390x

This repository maintains an unofficial port and repeatable build workflow for PowerShell on Linux s390x / IBM Z.

## Repository model

- `upstream`: official PowerShell repository
- `origin`: s390x port repository
- port branches: `port/vX.Y-s390x`
- port tags: `vX.Y.Z-s390x.N`

## Current validated port

- PowerShell: 7.6.0
- Branch: `port/v7.6-s390x`
- Port tag: `v7.6.0-s390x.1`
- Build RID: `rhel.9-s390x`
- Architecture: `s390x`
- .NET SDK used by the current branch: see `global.json`

## Build

Run the managed build:

```bash
./tools/s390x/build.sh
```

Build the native PowerShell library:

```bash
./tools/s390x/build-native.sh
```

Run validation tests:

```bash
./tools/s390x/test.sh
```

Create an exportable tarball:

```bash
./tools/s390x/package.sh /home/oper1
```

Full documentation is available in [`docs/s390x/build-checklist.md`](docs/s390x/build-checklist.md).

## Support status

This is an unofficial community port. It is not an official Microsoft PowerShell distribution for s390x.
