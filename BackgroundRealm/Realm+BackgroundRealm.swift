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


//MARK: - WRITE TRANSACTIONS
/**
 A BackgroundRealmTransaction is a closure that is executed in the background with a newly instantiated `Realm`.

 - parameters:
     - `Realm`:                 the background `Realm` instance if it was possible to open one.
     - `BackgroundRealm.Error`: a `BackgroundRealm.Error` describing what went wrong.
 */
public typealias BackgroundRealmTransaction = (Result<Realm, BackgroundRealm.Error>) -> Void


public extension Realm
{
    /**
     Upon calling this function, an `Operation` is added to `OperationQueue.backgroundRealm` which essentially:
     
     1. creates an autorelease pool
     2. opens a new `Realm` in the background
     3. calls `try realm.write {}` on the background `Realm`
     4. executes the `BackgroundTransaction` closure on the background `Realm`
     
     - parameters:
         - configuration:   an instance of `Realm.Configuration` used to open a new `Realm` in the background.
                            Defaults to `Realm.Configuration.backgroundConfiguration`.
                            If no `backgroundConfiguration` is set, a `Realm.Configuration.defaultConfiguration` is used.
         - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
         - closure:         the closure to be executed inside the background `try realm.write {}` call.
                            It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - [Note on autorelease pools](https://realm.io/docs/swift/latest/#threading)
     - `OperationQueue.backgroundRealm`
     */
    static func writeInBackground(configuration: Realm.Configuration? = .backgroundConfiguration,
                                  operationQueue queue: OperationQueue = .backgroundRealm,
                                  _ closure: @escaping BackgroundRealmTransaction)
    {
        Realm.executeInBackground(configuration: configuration ?? .defaultConfiguration,
                                  operationQueue: queue,
                                  closure)
    }
    
    /**
     Similar to `Realm.writeInBackground(configuration:_:)`, but using a `URL` instead of a `Configuration` to commit a write transaction in the background.
     
     - parameters:
        - fileURL:  the file URL used to open a new `Realm` in the background.
                    It defaults to using `Realm.Configuration.backgroundConfiguration` and setting its `fileURL` property.
                    If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.
        - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
        - closure:  the closure to be executed inside the background `try realm.write {}` call.
                    It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    static func writeInBackground(fileURL: URL,
                                  operationQueue queue: OperationQueue = .backgroundRealm,
                                  _ closure: @escaping BackgroundRealmTransaction)
    {
        var configuration = Realm.Configuration.backgroundConfiguration ?? Realm.Configuration.defaultConfiguration
        configuration.fileURL = fileURL

        Realm.executeInBackground(configuration: configuration,
                                  operationQueue: queue,
                                  closure)
    }
    
    /**
     Similar to `Realm.writeInBackground(configuration:_:)`, but using an existing `Realm`'s configuration to commit a write transaction in the background.
     
     If the existing `Realm`'s configuration is `nil`, this method defaults to `Realm.Configuration.backgroundConfiguration`.
     If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.
     
     - parameters:
        - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
        - closure:      the closure to be executed inside the background `try realm.write {}` call.
                        It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    func writeInBackground(operationQueue queue: OperationQueue = .backgroundRealm,
                           closure: @escaping BackgroundRealmTransaction)
    {
        let config = configuration
        Realm.executeInBackground(configuration: config,
                                  operationQueue: queue,
                                  closure)
    }

    
    //MARK: Private
    private static func executeInBackground(configuration: Realm.Configuration,
                                            operationQueue queue: OperationQueue = .backgroundRealm,
                                            _ closure: @escaping BackgroundRealmTransaction)
    {
        //Adding an `Operation` to `OperationQueue.backgroundRealm`
        queue.addOperation {
            do {
                //Creating an autorelease pool
                try autoreleasepool {
                    var config = configuration

                    //Making the background realm read only if needed
                    config.readOnly = false

                    let realm = try Realm(configuration: config)

                    //Disallowing autorefresh for performance reasons
                    realm.autorefresh = false

                    //Refreshing the background realm before writing, so to get a more up-to-date state
                    guard realm.refresh() else {
                        closure(.failure(.refresh))
                        return
                    }

                    //Write to the realm
                    try realm.write {
                        closure(.success(realm))
                    }
                }
            } catch let error as BackgroundRealm.Error {
                closure(.failure(error))
            } catch {
                closure(.failure(.generic(underlyingError: error)))
            }
        }
    }
}


//MARK: - COMMIT TRANSACTIONS
/**
 A CancellableBackgroundTransaction is a closure that is executed in the background with a newly instantiated `Realm`.

 - parameters:
     - `Realm`:                 the background `Realm` instance if it was possible to open one.
     - `BackgroundRealm.Error`: a `BackgroundRealm.Error` describing what went wrong.

 - returns:
    - Should cancel:            a boolean value indicating whether the closure should cancel its commit transaction.
                                If `true` is returned, `realm.cancelCommit()` is called instead of commiting changes to the `Realm`.
 */
public typealias CancellableBackgroundTransaction = (Result<Realm, BackgroundRealm.Error>) -> Bool


public extension Realm
{
    /**
     Upon calling this function, an `Operation` is added to `OperationQueue.backgroundRealm` which essentially:

     1. creates an autorelease pool
     2. opens a new `Realm` in the background
     3. calls `beginWrite()` on the background `Realm`
     4. executes the `CancellableBackgroundTransaction` closure on the background `Realm`
     5. calls `try realm.commitWrite()` on the background `Realm`

     - note:
        If `true` is returned from the transation closure, `cancelWrite()` is called on the background `Realm`.

     - parameters:
         - configuration:   an instance of `Realm.Configuration` used to open a new `Realm` in the background.
                            Defaults to `Realm.Configuration.backgroundConfiguration`.
                            If no `backgroundConfiguration` is set, a `Realm.Configuration.defaultConfiguration` is used.
         - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
         - closure:         the closure to be executed inside the background write transaction.
                            It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.

     ## See Also:
     - [Note on autorelease pools](https://realm.io/docs/swift/latest/#threading)
     - `OperationQueue.backgroundRealm`
     */
    static func commitInBackground(configuration: Realm.Configuration? = .backgroundConfiguration,
                                   operationQueue queue: OperationQueue = .backgroundRealm,
                                   _ closure: @escaping BackgroundRealmTransaction)
    {
        Realm.executeInBackground(configuration: configuration ?? .defaultConfiguration,
                                  operationQueue: queue,
                                  closure)
    }

    /**
     Similar to `Realm.commitInBackground(configuration:_:)`, but using a `URL` instead of a `Configuration` to commit a write transaction in the background.

     - parameters:
        - fileURL:  the file URL used to open a new `Realm` in the background.
                    It defaults to using `Realm.Configuration.backgroundConfiguration` and setting its `fileURL` property.
                    If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.
        - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
        - closure:  the closure to be executed inside the background `try realm.write {}` call.
                    It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.

     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    static func commitInBackground(fileURL: URL,
                                   operationQueue queue: OperationQueue = .backgroundRealm,
                                   _ closure: @escaping BackgroundRealmTransaction)
    {
        var configuration = Realm.Configuration.backgroundConfiguration ?? Realm.Configuration.defaultConfiguration
        configuration.fileURL = fileURL

        Realm.executeInBackground(configuration: configuration,
                                  operationQueue: queue,
                                  closure)
    }

    /**
     Similar to `Realm.commitInBackground(configuration:_:)`, but using an existing `Realm`'s configuration to commit a write transaction in the background.

     If the existing `Realm`'s configuration is `nil`, this method defaults to `Realm.Configuration.backgroundConfiguration`.
     If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.

     - parameters:
        - operationQueue:   the `OperationQueue` in which to run the `closure`. Defaults to `.backgroundRealm`.
        - closure:      the closure to be executed inside the background `try realm.write {}` call.
                        It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.

     ## See Also:
     - `Realm.writeInBackground(configuration:_:)`
     */
    func commitInBackground(operationQueue queue: OperationQueue = .backgroundRealm,
                            _ closure: @escaping BackgroundRealmTransaction)
    {
        let config = configuration
        Realm.executeInBackground(configuration: config,
                                  operationQueue: queue,
                                  closure)
    }


    //MARK: Private
    private static func executeInBackground(configuration: Realm.Configuration,
                                            operationQueue queue: OperationQueue = .backgroundRealm,
                                            _ closure: @escaping CancellableBackgroundTransaction)
    {
        //Adding an `Operation` to `OperationQueue.backgroundRealm`
        queue.addOperation {
            do {
                //Creating an autorelease pool
                try autoreleasepool {
                    var config = configuration

                    //Making the background realm read only if needed
                    config.readOnly = false

                    let realm = try Realm(configuration: config)

                    //Disallowing autorefresh for performance reasons
                    realm.autorefresh = false

                    //Refreshing the background realm before writing, so to get a more up-to-date state
                    guard realm.refresh() else {
                        let _ = closure(.failure(.refresh))
                        return
                    }

                    //Begin write transaction
                    realm.beginWrite()
                    guard closure(.success(realm)) == false else {
                        realm.cancelWrite()
                        return
                    }
                    try realm.commitWrite()
                }
            } catch let error as BackgroundRealm.Error {
                let _ = closure(.failure(error))
            } catch {
                let _ = closure(.failure(.generic(underlyingError: error)))
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
