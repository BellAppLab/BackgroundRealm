# Contributing to BackgroundRealm

## Installation

1. Fork and clone the repo
2. Download Realm into some folder in your machine (it's large and we don't want it in the repo)
    - [Earliest supported version](https://static.realm.io/downloads/swift/realm-swift-3.0.0.zip) - v3.0.0
    - [Latest supported version](https://static.realm.io/downloads/swift/realm-swift-5.3.3.zip) - v5.3.3
3. Rename the unzipped folder from `realm-swift-<version>` to `realm-swift-latest`
3. Navigate to your clone's folder and create a symbolic link to the Realm libraries
    - `ln -s <path/to/realm> ./Realm`
4. Add `Realm.framework` and `RealmSwift.framework` to the **iOS Example**, **tvOS Example** and **macOS Example** targets
    - Change the frameworks' embed strategy to **Embed & Sign**

## Changing Versions

* To change the **Xcode** version:
    - Go to *Project Navigator* > **Example** > **Example** > **Build Settings** > **XCODE_VERSION**
    - _Note 1_: This will automatically change the appropriate Realm version too
