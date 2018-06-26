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


//MARK: - ERRORS
extension BackgroundRealm
{
    /**
     The `BackgroundRealm.Error` enum describes the errors that may occur while dealing with the `BackgroundRealm` module.
     */
    public enum Error: Swift.Error, CustomStringConvertible
    {
        /// This error occurs when no `Realm.Configuration.backgroundConfiguration` has been set and no configuration has been passed to `Realm.writeInBackground`.
        case noBackgroundConfiguration
        
        /// During a write operation in the background, `BackgroundRealm` will try to refresh its `realm` before changing it. This error describes the situation where it wasn't possible to perform that refresh for some reason.
        case refresh
        
        /// A generic error, usually encapsulating an underlying error coming from `RealmSwift` itself.
        case generic(underlyingError: Swift.Error?)
        
        //MARK: - Error
        public var localizedDescription: String {
            switch self {
            case .generic(let underlyingError?):
                return underlyingError.localizedDescription
            case .generic(_):
                return "Something went wrong while using Background Realm. This shouldn't ever happen though... Please go to https://github.com/BellAppLab/BackgroundRealm/issues and talk to us about it."
            case .noBackgroundConfiguration:
                return "Trying to write a transaction to a Realm in the background, but `Realm.Configuration.backgroundConfiguration` is empty."
            case .refresh:
                return "Couldn't refresh a background Realm"
            }
        }
        
        //MARK: - String Convertible
        public var description: String {
            return "\(self): \(localizedDescription)"
        }
    }
}


//MARK: - EQUATABLE
extension BackgroundRealm.Error: Equatable
{
    public static func ==(lhs: BackgroundRealm.Error, rhs: BackgroundRealm.Error) -> Bool {
        switch (lhs, rhs) {
        case (.generic(let lError), .generic(let rError)):
            return lError?.localizedDescription == rError?.localizedDescription
        case (.noBackgroundConfiguration, .noBackgroundConfiguration),
             (.refresh, .refresh):
            return true
        default:
            return false
        }
    }
}
