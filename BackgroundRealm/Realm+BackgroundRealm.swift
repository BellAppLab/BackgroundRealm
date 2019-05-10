/*
 Copyright (c) 2018 Bell App Lab <apps@bellapplab.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation
import RealmSwift


//MARK: - CONFIGURATION
public extension Realm.Configuration
{
    /**
     The default background configuration that `BackgroundRealm` uses to commit write transactions in the background.
     
     - note: When no `Realm.Configuration.backgroundConfiguration` is set, you must pass a valid configuration to `Realm.writeInBackground`.
     
     ## See Also:
     - `Realm.writeInBackground`
     */
    @nonobjc
    static var backgroundConfiguration: Realm.Configuration?
}


//MARK: - TRANSACTIONS
@nonobjc
public extension Realm
{
    /**
     Upon calling this function, an `Operation` is added to `Realm.operationQueue` which essentially:
     
     1. creates an autorelease pool
     2. tries to find a `Realm.Configuration` to open a new `Realm` with
     3. opens a new `Realm` in the background
     4. calls `try realm.write {}` on the background `Realm`
     
     - parameters:
         - configuration:   an instance of `Realm.Configuration` used to open a new `Realm` in the background.
                            If no `Configuration` is provided, it defaults to `Realm.Configuration.backgroundConfiguration`.
                            If no `backgroundConfiguration` is set, a `BackgroundRealm.Error.noBackgroundConfiguration` is returned.
                            Defaults to `nil`.
         - closure:         the closure to be executed inside the background `try realm.write {}` call.
                            It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - [Note on autorelease pools](https://realm.io/docs/swift/latest/#threading)
     - `BackgroundRealm.Error.noBackgroundConfiguration`
     - `Realm.operationQueue`
     */
    static func writeInBackground(configuration: Realm.Configuration? = nil,
                                  _ closure: @escaping ((Realm?, BackgroundRealm.Error?) -> Void))
    {
        Realm.commitTransactionInBackground(configuration: configuration, closure)
    }
    
    /**
     Similar to `Realm.writeInBackground(configuration:_:)`, but using a `URL` instead of a `Configuration` to commit a write transaction in the background.
     
     - parameters:
        - fileURL:  the file URL used to open a new `Realm` in the background.
                    It defaults to using `Realm.Configuration.backgroundConfiguration` and setting its `fileURL` property.
                    If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.
        - closure:  the closure to be executed inside the background `try realm.write {}` call.
                    It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    static func writeInBackground(fileURL: URL,
                                  _ closure: @escaping ((Realm?, BackgroundRealm.Error?) -> Void))
    {
        var configuration = Realm.Configuration.backgroundConfiguration ?? Realm.Configuration.defaultConfiguration
        configuration.fileURL = fileURL
        
        Realm.commitTransactionInBackground(configuration: configuration, closure)
    }
    
    /**
     Similar to `Realm.writeInBackground(configuration:_:)`, but using an existing `Realm`'s configuration to commit a write transaction in the background.
     
     If the existing `Realm`'s configuration is `nil`, this method defaults to `Realm.Configuration.backgroundConfiguration`.
     If no `backgroundConfiguration` is set, a `BackgroundRealm.Error.noBackgroundConfiguration` is returned.
     
     - parameters:
        - closure:      the closure to be executed inside the background `try realm.write {}` call.
                        It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    func writeInBackground(_ closure: @escaping ((Realm?, BackgroundRealm.Error?) -> Void))
    {
        let configuration = self.configuration
        Realm.commitTransactionInBackground(configuration: configuration, closure)
    }
    
    //MARK: - Private
    private static func commitTransactionInBackground(configuration: Realm.Configuration?,
                                                      _ closure: @escaping ((Realm?, BackgroundRealm.Error?) -> Void))
    {
        //Adding an `Operation` is added to `Realm.operationQueue`
        OperationQueue.backgroundRealm.addOperation {
            do {
                //Creating an autorelease pool
                try autoreleasepool {
                    //Finding the right configuration
                    var config: Realm.Configuration
                    switch (configuration, Realm.Configuration.backgroundConfiguration) {
                    case (let value?, _),
                         (_, let value?):
                        config = value
                    case (nil, _),
                         (_, nil):
                        closure(nil, .noBackgroundConfiguration)
                        return
                    }
                    
                    //Making the background realm writable
                    config.readOnly = false
                    
                    let realm = try Realm(configuration: config)
                    //Disallowing autorefresh for performance reasons
                    realm.autorefresh = false
                    
                    //Refreshing the background realm before writing, so to get a more up-to-date state
                    guard realm.refresh() else {
                        closure(nil, .refresh)
                        return
                    }
                    
                    //Writing to the realm
                    try realm.write {
                        closure(realm, nil)
                    }
                }
            } catch let error as BackgroundRealm.Error {
                closure(nil, error)
            } catch {
                closure(nil, .generic(underlyingError: error))
            }
        }
    }
}


//MARK: - QUEUES
@nonobjc
public extension DispatchQueue
{
    /// The dispatch queue used to commit background write operations to Realm.
    static var backgroundRealm: DispatchQueue = {
        let result = DispatchQueue(label: "BackgroundRealm.Queue", qos: DispatchQoS.utility)
        return result
    }()
}


@nonobjc
public extension OperationQueue
{
    /// The opertation queue used to commit background write operations to Realm.
    static var backgroundRealm: OperationQueue = {
        let result = OperationQueue()
        result.name = "BackgroundRealm.OperationQueue"
        result.underlyingQueue = .backgroundRealm
        result.maxConcurrentOperationCount = 1
        return result
    }()
}
