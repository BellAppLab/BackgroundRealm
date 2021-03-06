import XCTest
import RealmSwift
@testable import BackgroundRealm


class BackgroundRealm_Tests: XCTestCase
{
    var defaultBackgroundRealm: BackgroundRealm?
    var backgroundBackgroundRealm: BackgroundRealm?
    var customBackgroundRealm: BackgroundRealm?
    var fileBackgroundRealm: BackgroundRealm?
    var updateBackgroundRealm: BackgroundRealm?
    
    func testInitialisingBackgroundRealmWithTheDefaultConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm from Realm.Configuration.default")

        let dontExpectError = expectation(description: "We should be able to get a background Realm with no errors")
        dontExpectError.isInverted = true
        
        defaultBackgroundRealm = BackgroundRealm { [weak self] (result) in
            defer {
                self?.defaultBackgroundRealm = nil
            }

            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")

            switch result {
            case let .failure(error):
                print("ERROR: \(error)")
                dontExpectError.fulfill()
            case .success:
                expectRealm.fulfill()
            }
        }
        
        wait(for: [expectRealm, dontExpectError],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithTheBackgroundConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm from Realm.Configuration.backgroundConfiguration")

        let dontExpectError = expectation(description: "We should be able to get a background Realm with no errors")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithTheBackgroundConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        backgroundBackgroundRealm = BackgroundRealm { [weak self] (result) in
            defer {
                self?.backgroundBackgroundRealm = nil
            }

            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")

            switch result {
            case let .failure(error):
                print("ERROR: \(error)")
                dontExpectError.fulfill()
            case let .success(realm):
                XCTAssertNotNil(realm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(realm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!, "The background realm's URL should be equal to the one set on Realm.Configuration.backgroundConfiguration")
                
                expectRealm.fulfill()
            }
        }
        
        wait(for: [expectRealm, dontExpectError],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithCustomConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm with a custom configuration")

        let dontExpectError = expectation(description: "We should be able to get a background Realm with no errors")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithCustomConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        let backgroundConfiguration = Realm.Configuration(fileURL: Realm.Configuration.defaultConfiguration.fileURL!)
        Realm.Configuration.backgroundConfiguration = backgroundConfiguration
        
        let configuration = Realm.Configuration(fileURL: url!)
        customBackgroundRealm = BackgroundRealm(configuration: configuration) { [weak self] (result) in
            defer {
                self?.customBackgroundRealm = nil
            }
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")

            switch result {
            case let .failure(error):
                print("ERROR: \(error)")
                dontExpectError.fulfill()
            case let .success(realm):
                XCTAssertNotNil(realm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(realm.configuration.fileURL!, configuration.fileURL!, "The background realm's URL should be equal to the one set upon initialisation")
                XCTAssertNotEqual(realm.configuration.fileURL!, backgroundConfiguration.fileURL!, "The background realm's URL should be equal to the one set upon initialisation")

                expectRealm.fulfill()
            }
        }
        
        wait(for: [expectRealm, dontExpectError],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithFileURL() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm with a custom file URL")

        let dontExpectError = expectation(description: "We should be able to get a background Realm with no errors")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        fileBackgroundRealm = BackgroundRealm(fileURL: url!) { [weak self] (result) in
            defer {
                self?.fileBackgroundRealm = nil
            }
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")

            switch result {
            case let .failure(error):
                print("ERROR: \(error)")
                dontExpectError.fulfill()
            case let .success(realm):
                XCTAssertNotNil(realm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(realm.configuration.fileURL!, url!, "The background realm's URL should be equal to the one set upon initialisation")
                XCTAssertNotEqual(realm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration?.fileURL, "The background realm's URL should be equal to the one set upon initialisation")

                expectRealm.fulfill()
            }
        }
        
        wait(for: [expectRealm, dontExpectError],
             timeout: 3)
    }
    
    var backgroundWriteToken: NotificationToken?
    
    func testReceivingBackgroundChangesFromBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a background notification from a write transaction initated by a call to `realm.writeInBackground`")
        let dontExpectError = expectation(description: "We should not get an error on the write callback")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingBackgroundChangesFromBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        updateBackgroundRealm = BackgroundRealm { [weak self] (result) in
            switch result {
            case let .failure(error):
                print("ERROR: \(error)")
                dontExpectError.fulfill()
                return
            case .success:
                break
            }

            guard let realm = try? result.get() else { XCTFail(); return }
            
            do {
                realm.beginWrite()
                realm.deleteAll()
                try realm.commitWrite()
            } catch {
                XCTFail("\(error)")
                expectWrite.fulfill()
            }
            
            self?.backgroundWriteToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    self?.updateBackgroundRealm = nil
                    self?.backgroundWriteToken = nil
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
                    self?.updateBackgroundRealm = nil
                    self?.backgroundWriteToken = nil
                    expectWrite.fulfill()
                }
            })
            
            XCTAssertNotNil(self?.backgroundWriteToken, "The observation token shouldn't be nil here")
            
            realm.writeInBackground { (result) in
                switch result {
                case .success(let bgRealm):
                    let object = TestObject()
                    object.name = name
                    bgRealm.add(object)
                case .failure(_):
                    dontExpectError.fulfill()
                }
            }
        }
        
        wait(for: [expectWrite, dontExpectError],
             timeout: 5)
    }
}
