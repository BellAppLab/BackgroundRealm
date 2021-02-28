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


//MARK: - BACKGROUND WORKER
/**
 Loads private `Thread` with a `RunLoop` so a `Realm` in the background can receive updates.
 
 ## See Also:
 - [Source](https://academy.realm.io/posts/realm-notifications-on-background-threads-with-swift/)
 */
@objc
class BackgroundWorker: NSObject
{
    deinit {
        stop()
    }
    
    @nonobjc
    private var thread: Thread?
    
    @nonobjc
    private var block: (()->Void)!
    
    @objc
    var isRunning: Bool {
        return !(thread?.isCancelled ?? false)
    }
    
    @objc
    func runBlock() { block() }
    
    @objc
    func start(_ block: @escaping () -> Void) {
        if isRunning {
            stop()
        }
        
        self.block = block
        
        let threadName = String(describing: self)
            .components(separatedBy: .punctuationCharacters)[1]
        
        thread = Thread(target: self,
                        selector: #selector(runRunLoop),
                        object: nil)
        thread?.name = "\(threadName)-\(UUID().uuidString)"
        thread?.start()
        
        perform(#selector(runBlock),
                on: thread!,
                with: nil,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
    }
    
    @objc
    func runRunLoop() {
        while (self.isRunning) {
            RunLoop.current.run(
                mode: RunLoop.Mode.default,
                before: Date.distantFuture)
        }
        Thread.exit()
    }
    
    @objc
    func stop() {
        thread?.cancel()
        thread = nil
    }
}


//MARK: - BACKGROUND REALM
/**
 A `BackgroundRealm` essentially:
 
 1. creates a private `Thread` and `RunLoop` where a new background `Realm` will be opened
 2. opens a `Realm` in the private thread
 3. executes the `completion` closure in the background thread
 
 Upon successfully opening the `Realm` in the background, the `completion` closure is executed, which gives clients a chance to:
 
 - make computationally expensive changes to the `Realm`, or
 - register for change notifications in the background
 
 This is particularly useful if you'd like to be notified of changes to a `Realm` but not necessarily want to trigger a UI update right away.
 
 - warning: Although a `BackgroundRealm` can be created from any thread, it does **not** make its underlying `Realm` nor its objects thread-safe. They should still be accessed only from within their appropriate thread. In other words, **it is not safe** to use the underlying `Realm` in your apps UI.
 
 ## See Also:
 - `BackgroundRealm.init(configuration:_:)`
 */
public final class BackgroundRealm
{
    //MARK: - Properties
    @nonobjc
    internal let _configuration: Realm.Configuration
    
    @nonobjc
    private lazy var backgroundWorker = BackgroundWorker()
    
    @nonobjc
    internal private(set) var underlyingRealm: Realm?
    
    /// The `Schema` used by the underlying `Realm`.
    @nonobjc
    public var schema: Schema? { return underlyingRealm?.schema }
    
    /// The `Configuration` value that was used to create the underlying `Realm` instance.
    @nonobjc
    public var configuration: Realm.Configuration? { return underlyingRealm?.configuration }
    
    /// Indicates if the underlying `Realm` contains any objects.
    @nonobjc
    public var isEmpty: Bool { return underlyingRealm?.isEmpty ?? true }
    
    //MARK: - Initializers
    public typealias SetupCallback = (Result<Realm, BackgroundRealm.Error>) -> Void
    /**
     Obtains a `BackgroundRealm` instance with the given configuration.
     
     - parameters:
        - configuration:    a configuration value to use when creating the `Realm`.
                            Defaults to `Realm.Configuration.backgroundConfiguration`.
        - completion:       a closure to be executed once the `BackgroundRealm` creates its underlying `Realm` in the background.
                            It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     */
    @nonobjc
    public init(configuration: Realm.Configuration? = Realm.Configuration.backgroundConfiguration,
                _ completion: @escaping SetupCallback)
    {
        self._configuration = configuration ?? Realm.Configuration.defaultConfiguration
        setup(completion)
    }
    
    /**
     Similar to `BackgroundRealm.init(configuration:_:)`, but using a `URL` instead of a `Configuration` to create the underlying `Realm`.
     
     - parameters:
        - fileURL:          the file URL used to open a new `Realm` in the background.
                            It defaults to using `Realm.Configuration.backgroundConfiguration` and setting its `fileURL` property.
                            If no `backgroundConfiguration` is set, `Realm.Configuration.defaultConfiguration` is used.
        - completion:       a closure to be executed once the `BackgroundRealm` creates its underlying `Realm` in the background.
                            It receives two arguments:
            - `Realm`:                  the background `Realm` instance if it was possible to open one.
            - `BackgroundRealm.Error`:  a `BackgroundRealm.Error` describing what went wrong.
     
     ## See Also:
     - `BackgroundRealm.init(configuration:_:)`
     */
    @nonobjc
    public convenience init(fileURL: URL,
                            _ completion: @escaping SetupCallback)
    {
        var configuration = Realm.Configuration.backgroundConfiguration ?? Realm.Configuration.defaultConfiguration
        configuration.fileURL = fileURL
        self.init(configuration: configuration, completion)
    }

    /**
     Unavailable. Please use the `Result<Realm, BackgroundRealm.Error>>` callback instead.
     */
    @available(*, unavailable)
    @nonobjc
    public convenience init(fileURL: URL,
                            _ completion: @escaping ((Realm?, BackgroundRealm.Error?) -> Void))
    {
        fatalError()
    }
    
    @nonobjc
    private func setup(_ completion: @escaping SetupCallback)
    {
        let configuration = _configuration
        
        // According to Realm's docs (https://realm.io/docs/swift/3.0.0/#opening-a-synchronized-realm),
        // synchronised, read-only Realms must be opened using `asyncOpen`
        if configuration.syncConfiguration != nil, configuration.readOnly == true {
            Realm.asyncOpen(configuration: configuration,
                            callbackQueue: .backgroundRealm)
            { (result) in
                completion(result.mapError(BackgroundRealm.Error.generic))
            }
            return
        }
        
        backgroundWorker.start { [weak self] in
            completion(Result(catching: {
                let realm = try Realm(configuration: configuration)
                self?.underlyingRealm = realm
                return realm
            })
            .mapError(BackgroundRealm.Error.generic))
        }
    }
}


//MARK: - EQUATABLE
@nonobjc
extension BackgroundRealm: Equatable {
    /// Returns whether two `BackgroundRealm` instances are equal.
    public static func ==(lhs: BackgroundRealm, rhs: BackgroundRealm) -> Bool {
        guard let lhsRealm = lhs.underlyingRealm, let rhsRealm = rhs.underlyingRealm else {
            return lhs === rhs
        }
        return lhsRealm == rhsRealm
    }
}
