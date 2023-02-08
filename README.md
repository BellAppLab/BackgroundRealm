# Background Realm [![Version](https://img.shields.io/badge/Version-4.0.0-black.svg?style=flat)](#installation) [![License](https://img.shields.io/cocoapods/l/BackgroundRealm.svg?style=flat)](#license)

[![Platforms](https://img.shields.io/badge/Platforms-iOS|tvOS|macOS|watchOS-brightgreen.svg?style=flat)](#installation)
[![Swift support](https://img.shields.io/badge/Swift-5.3%20%7C%205.7-red.svg?style=flat)](#swift-versions-support)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BackgroundRealm.svg?style=flat&label=CocoaPods)](https://cocoapods.org/pods/BackgroundRealm)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-red.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Twitter](https://img.shields.io/badge/Twitter-@BellAppLab-blue.svg?style=flat)](http://twitter.com/BellAppLab)

![Background Realm](./Images/background_realm.png)

Background Realm is a collection of handy classes and extensions that make it easier to work with `RealmSwift` in the background.

It's main focus is to enhance existing `Realm`s and Realm-based code bases with very little overhead and refactoring. 

**Note**: Although this module makes it more convenient to work with a `Realm` in the background, it does **not** make  `Realm`s nor its objects thread-safe. They should still be accessed only from within their appropriate thread.

## Specs

* RealmSwift 10.0.0+
* iOS 12+
* tvOS 12+
* watchOS 4+
* macOS 10.13+
* Swift 5.0+

### Objective-C

For the Objective-C counterpart, see [BLBackgroundRealm](https://github.com/BellAppLab/BLBackgroundRealm).

## Writing to a Realm in the background

Performing write transactions in the background becomes as easy as:

```swift
Realm.writeInBackground(configuration: <#T##Realm.Configuration?#>) { (result) in
    <#code#>
}
```

Optionally, you can set a default `backgroundConfiguration` that will be used in all write transactions in the background:

```swift
Realm.Configuration.backgroundConfiguration = <#T##Realm.Configuration?#>

Realm.writeInBackground { (result) in
    <#code#>
}
```

Finally, you can easily move from any `Realm` instance to its background counterpart:

```swift
let realm = try Realm()

realm.writeInBackground { (result) in 
    <#code#>
}
```

## Commiting to a Realm in the background

Similarly to write operations, you can commit transactinos to a `Realm` in the background. The difference being that commits can be cancelled:

```swift
Realm.commitInBackground(configuration: <#T##Realm.Configuration?#>) { (result) -> Bool in
    <#code#>
    return false //return true if you want to cancel this write operation
}
```

You can also move from any `Realm` instance to its background counterpart:

```swift
let realm = try Realm()

realm.commitInBackground { (result) -> Bool in 
    <#code#>
    return false //return true if you want to cancel this write operation
}
```

## The `BackgroundRealm`

Background Realm exposes a `BackgroundRealm`  class, which basically:

1. creates a private `Thread` and `RunLoop` where a new background `Realm` will be opened
2. opens a `Realm` in the private thread
3. runs work in the background thread

This is particularly useful if you'd like to:

- make computationally expensive changes to the `Realm`
- register for change notifications in the background, without necessarily triggering a UI update right away

### Usage

- Creating a `BackgroundRealm` using `Realm.Configuration.backgroundConfiguration`:

```swift
let backgroundRealm = BackgroundRealm { (result) in
    <#code#>
}
```

- Creating a `BackgroundRealm` using a custom configuration:

```swift
let backgroundRealm = BackgroundRealm(configuration: <#T##Realm.Configuration?#>) { (result) in
    <#code#>
}
```

- Creating a `BackgroundRealm` using a file `URL`:

```swift
let backgroundRealm = BackgroundRealm(fileURL: <#T##URL#>) { (result) in
    <#code#>
}
```

## Queues

`BackgroundRealm` uses two queues to process things in the background: 

- `DispatchQueue.backgroundRealm`
- `OperationQueue.backgroundRealm`

If you'd like to use your own queues, just set those as early as possible in you app's life cycle.

## Installation

### Cocoapods

```ruby
pod 'BackgroundRealm', '~> 4.0'
```

Then `import BackgroundRealm` where needed.

### Carthage

```swift
github "BellAppLab/BackgroundRealm" ~> 4.0
```

Then `import BackgroundRealm` where needed.

### Swift Package Manager

```swift
.package(url: "https://github.com/BellAppLab/BackgroundRealm.git", from: "4.0.0")
```

### Git Submodules

```shell
cd toYourProjectsFolder
git submodule add -b submodule --name BackgroundRealm https://github.com/BellAppLab/BackgroundRealm.git
```

Then drag the `BackgroundRealm` folder into your Xcode project.

## Author

Bell App Lab, apps@bellapplab.com

### Contributing

Check [this out](./CONTRIBUTING.md).

### Credits

[Logo image](https://thenounproject.com/search/?q=background&i=635453#) by [mikicon](https://thenounproject.com/mikicon) from [The Noun Project](https://thenounproject.com/)

## License

BackgroundRealm is available under the MIT license. See the LICENSE file for more info.
