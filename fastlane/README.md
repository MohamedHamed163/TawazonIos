fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios bootstrap_signing

```sh
[bundle exec] fastlane ios bootstrap_signing
```

ONE-TIME, run locally: create the shared cert + App Store profile and push them to the match repo

### ios refresh_signing

```sh
[bundle exec] fastlane ios refresh_signing
```

Re-mint the shared cert + App Store profile after the old cert was revoked/expired, then push to the match repo. Uses the ASC API key — no interactive Apple ID login.

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build a Release archive and upload it to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
