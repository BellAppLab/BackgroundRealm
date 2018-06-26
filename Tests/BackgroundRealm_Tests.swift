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
    
    override func setUp() {
        super.setUp()
        
        Realm.Configuration.backgroundConfiguration = nil
        defaultBackgroundRealm = nil
        backgroundBackgroundRealm = nil
        customBackgroundRealm = nil
        fileBackgroundRealm = nil
        updateBackgroundRealm = nil
    }
    
    func testInitialisingBackgroundRealmWithTheDefaultConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm from Realm.Configuration.default")
        
        defaultBackgroundRealm = BackgroundRealm { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithTheBackgroundConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm from Realm.Configuration.backgroundConfiguration")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithTheBackgroundConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        backgroundBackgroundRealm = BackgroundRealm { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
            
            XCTAssertNotNil(realm!.configuration.fileURL, "The background realm's configuration shouldn't be empty")
            XCTAssertEqual(realm!.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!, "The background realm's URL should be equal to the one set on Realm.Configuration.backgroundConfiguration")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithCustomConfiguration() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm with a custom configuration")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithCustomConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: Realm.Configuration.defaultConfiguration.fileURL!)
        
        let configuration = Realm.Configuration(fileURL: url!)
        customBackgroundRealm = BackgroundRealm(configuration: configuration) { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
            
            XCTAssertNotNil(realm!.configuration.fileURL, "The background realm's configuration shouldn't be empty")
            XCTAssertEqual(realm!.configuration.fileURL!, configuration.fileURL!, "The background realm's URL should be equal to the one set upon initialisation")
            XCTAssertNotEqual(realm!.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!, "The background realm's URL should be equal to the one set upon initialisation")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInitialisingBackgroundRealmWithFileURL() {
        let expectRealm = expectation(description: "We should be able to create a BackgroundRealm with a custom file URL")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInitialisingBackgroundRealmWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        fileBackgroundRealm = BackgroundRealm(fileURL: url!) { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            
            XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
            
            XCTAssertNotNil(realm!.configuration.fileURL, "The background realm's configuration shouldn't be empty")
            XCTAssertEqual(realm!.configuration.fileURL!, url!, "The background realm's URL should be equal to the one set upon initialisation")
            XCTAssertNotEqual(realm!.configuration.fileURL!, Realm.Configuration.backgroundConfiguration?.fileURL, "The background realm's URL should be equal to the one set upon initialisation")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    var backgroundWriteToken: NotificationToken?
    
    func testReceivingBackgroundChangesFromBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a background notification from a write transaction initated by a call to `realm.writeInBackground`")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingBackgroundChangesFromBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        updateBackgroundRealm = BackgroundRealm { [weak self] (realm, error) in
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            
            do {
                realm?.beginWrite()
                realm?.deleteAll()
                try realm?.commitWrite()
            } catch {
                XCTFail("\(error)")
                expectWrite.fulfill()
            }
            
            self?.backgroundWriteToken = realm?.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    XCTAssertNotEqual(Thread.current, Thread.main, "We should be in the background")
                    expectWrite.fulfill()
                }
            })
            
            XCTAssertNotNil(self?.backgroundWriteToken, "The observation token shouldn't be nil here")
            
            realm?.writeInBackground { (bgRealm, _) in
                let object = TestObject()
                object.name = name
                bgRealm?.add(object)
            }
        }
        
        wait(for: [expectWrite],
             timeout: 5)
    }
}
