import XCTest
import RealmSwift
@testable import BackgroundRealm


class Realm_Background_Write_Tests: XCTestCase
{
    override func setUp() {
        super.setUp()
        
        Realm.Configuration.backgroundConfiguration = nil
        staticBackgroundWriteToken = nil
        instanceBackgroundWriteToken = nil
    }
    
    func testInstanceWriteInBackgroundWithNoConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with the default configuration")

        do {
            let realm = try Realm()
            realm.writeInBackground { (result) in
                defer { expectRealm.fulfill() }

                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testStaticWriteInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.writeInBackground` with a background file URL set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticWriteInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.writeInBackground(fileURL: url!) { (result) in
            defer { expectRealm.fulfill() }

            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(bgRealm.configuration.fileURL, url, "The background realm's URL should be equal to \(url!)")
            case .failure(let error):
                XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
            }
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInstanceWriteInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with a background file URL set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceWriteInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        do {
            let realm = try Realm(fileURL: url!)
            realm.writeInBackground { (result) in
                defer { expectRealm.fulfill() }

                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                    XCTAssertEqual(bgRealm.configuration.fileURL, url!, "The background realm's URL should be equal to \(url!)")
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testStaticWriteInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.writeInBackground` with a background configuration set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticWriteInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        Realm.writeInBackground { (result) in
            defer { expectRealm.fulfill() }

            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(bgRealm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!,
                               "The background realm's URL should be equal to the one set on Realm.Configuration.backgroundConfiguration")
            case .failure(let error):
                XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
            }
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInstanceWriteInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with a background configuration set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceWriteInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        do {
            let realm = try Realm(fileURL: url!)
            realm.writeInBackground { (result) in
                defer { expectRealm.fulfill() }

                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                    XCTAssertEqual(bgRealm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!,
                                   "The background realm's URL should be equal to \(url!)")
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    var staticBackgroundWriteToken: NotificationToken?
    
    func testReceivingChangesFromStaticBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `Realm.writeInBackground`")
        let dontExpectError = expectation(description: "We should not get an error on the write callback")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromStaticBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        
        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()
            
            staticBackgroundWriteToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }
        
        Realm.writeInBackground { (result) in
            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                let object = TestObject()
                object.name = name
                bgRealm.add(object)
            case .failure(let error):
                print("\(error)")
                dontExpectError.fulfill()
            }
        }
        
        wait(for: [expectWrite, dontExpectError],
             timeout: 5)
    }
    
    var instanceBackgroundWriteToken: NotificationToken?
    
    func testReceivingChangesFromInstanceBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `realm.writeInBackground`")
        let dontExpectError = expectation(description: "We should not get an error on the write callback")
        dontExpectError.isInverted = true
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromInstanceBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        
        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()
            
            instanceBackgroundWriteToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })
            
            realm.writeInBackground { (result) in
                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    let object = TestObject()
                    object.name = name
                    bgRealm.add(object)
                case .failure(let error):
                    print("\(error)")
                    dontExpectError.fulfill()
                }
            }
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }
        
        wait(for: [expectWrite, dontExpectError],
             timeout: 5)
    }
}


class Realm_Background_Commit_Tests: XCTestCase
{
    override func setUp() {
        super.setUp()

        Realm.Configuration.backgroundConfiguration = nil
        staticBackgroundCommitToken = nil
        instanceBackgroundCommitToken = nil
    }

    func testInstanceCommitInBackgroundWithNoConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.commitInBackground` with the default configuration")

        do {
            let realm = try Realm()
            realm.commitInBackground { (result) in
                defer { expectRealm.fulfill() }

                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }

        wait(for: [expectRealm],
             timeout: 3)
    }

    func testStaticCommitInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.commitInBackground` with a background file URL set")

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticCommitInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        Realm.commitInBackground(fileURL: url!) { (result) in
            defer { expectRealm.fulfill() }

            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(bgRealm.configuration.fileURL, url, "The background realm's URL should be equal to \(url!)")
            case .failure(let error):
                XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
            }
        }

        wait(for: [expectRealm],
             timeout: 3)
    }

    func testInstanceCommitInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.commitInBackground` with a background file URL set")

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceCommitInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        do {
            let realm = try Realm(fileURL: url!)
            realm.commitInBackground { (result) in
                defer { expectRealm.fulfill() }

                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                    XCTAssertEqual(bgRealm.configuration.fileURL, url!, "The background realm's URL should be equal to \(url!)")
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }

        wait(for: [expectRealm],
             timeout: 3)
    }

    func testStaticCommitInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.commitInBackground` with a background configuration set")

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticCommitInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        Realm.commitInBackground { (result) in
            defer { expectRealm.fulfill() }

            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(bgRealm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!,
                               "The background realm's URL should be equal to the one set on Realm.Configuration.backgroundConfiguration")
            case .failure(let error):
                XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
            }
        }

        wait(for: [expectRealm],
             timeout: 3)
    }

    func testInstanceCommitInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.commitInBackground` with a background configuration set")

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceCommitInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        do {
            let realm = try Realm(fileURL: url!)
            realm.commitInBackground { (result) in
                defer { expectRealm.fulfill() }

                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    XCTAssertNotNil(bgRealm.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                    XCTAssertEqual(bgRealm.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!,
                                   "The background realm's URL should be equal to \(url!)")
                case .failure(let error):
                    XCTFail("We should be able to get a background Realm with no errors, but got one: \(error)")
                }
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }

        wait(for: [expectRealm],
             timeout: 3)
    }

    var staticBackgroundCommitToken: NotificationToken?

    func testReceivingChangesFromStaticBackgroundCommit() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `Realm.commitInBackground`")
        let dontExpectError = expectation(description: "We should not get an error on the write callback")
        dontExpectError.isInverted = true

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromStaticBackgroundCommit.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)

        let name = "TEST TEST"

        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()

            staticBackgroundCommitToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }

        Realm.commitInBackground { (result) in
            XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

            switch result {
            case .success(let bgRealm):
                let object = TestObject()
                object.name = name
                bgRealm.add(object)
            case .failure(let error):
                print("\(error)")
                dontExpectError.fulfill()
            }
        }

        wait(for: [expectWrite, dontExpectError],
             timeout: 5)
    }

    var instanceBackgroundCommitToken: NotificationToken?

    func testReceivingChangesFromInstanceBackgroundCommit() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `realm.commitInBackground`")
        let dontExpectError = expectation(description: "We should not get an error on the write callback")
        dontExpectError.isInverted = true

        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromInstanceBackgroundCommit.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")

        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)

        let name = "TEST TEST"

        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()

            instanceBackgroundCommitToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })

            realm.commitInBackground { (result) in
                XCTAssert(Thread.current != Thread.main, "This should be executed in a background thread")

                switch result {
                case .success(let bgRealm):
                    let object = TestObject()
                    object.name = name
                    bgRealm.add(object)
                case .failure(let error):
                    print("\(error)")
                    dontExpectError.fulfill()
                }
            }
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }

        wait(for: [expectWrite, dontExpectError],
             timeout: 5)
    }
}

