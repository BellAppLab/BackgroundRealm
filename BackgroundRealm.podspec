Pod::Spec.new do |s|

  s.name                = "BackgroundRealm"
  s.version             = "2.0.1"
  s.summary             = "A collection of handy classes and extensions that make it easier to work with `RealmSwift` in the background."
  s.screenshot          = "https://github.com/BellAppLab/BackgroundRealm/raw/master/Images/background_realm.png"

  s.description         = <<-DESC
Background Realm is a collection of handy classes and extensions that make it easier to work with `RealmSwift` in the background.

It's main focus is to enhance existing `Realm`s and Realm-based code bases with very little overhead and refactoring.

**Note**: Although this module makes it more convenient to work with a `Realm` in the background, it does **not** make  `Realm`s nor its objects thread-safe. They should still be accessed only from within their appropriate thread.

For the Objective-C counterpart, see [BLBackgroundRealm](https://github.com/BellAppLab/BLBackgroundRealm).
                   DESC

  s.homepage            = "https://github.com/BellAppLab/BackgroundRealm"

  s.license             = { :type => "MIT", :file => "LICENSE" }

  s.author              = { "Bell App Lab" => "apps@bellapplab.com" }
  s.social_media_url    = "https://twitter.com/BellAppLab"

  s.swift_version       = '5.0'

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.tvos.deployment_target = "10.0"
  s.watchos.deployment_target = "3.0"

  s.module_name         = 'BackgroundRealm'

  s.source              = { :git => "https://github.com/BellAppLab/BackgroundRealm.git", :tag => "#{s.version}" }

  s.source_files        = "BackgroundRealm"

  s.framework           = "Foundation"
  s.dependency          'Realm', '~> 4.0'
  s.dependency          'RealmSwift', '~> 4.0'

end
