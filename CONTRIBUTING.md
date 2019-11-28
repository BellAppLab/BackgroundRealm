# Contributing to BackgroundRealm

## Installation

1. Fork and clone the repo
2. Download Realm into some folder in your machine (it's large and we don't want it in the repo)
    - [Earliest supported version](https://static.realm.io/downloads/swift/realm-swift-3.0.0.zip) - v3.0.0
    - [Latest supported version](https://static.realm.io/downloads/swift/realm-swift-4.1.1.zip) - v3.11.1
3. Navigate to your clone's folder and create a symbolic link to the Realm libraries
    - `ln -s <path/to/realm> ./Realm`

## Changing Versions

* To change the **Swift** version:
    - Go to *Project Navigator* > **Example** > **Example** > **Build Settings** > **Swift Version**
    - _Note 1_: This will automatically change the appropriate Realm version too
    - _Note_2_: Realm v3.0.0 only supports Swift v4.0

* To change the **Realm** version:
    - Go to *Project Navigator* > **Example** > **Example** > **Build Settings** > **REALM_VERSION**
    - _Note 1_: This will automatically change the appropriate Realm version too
