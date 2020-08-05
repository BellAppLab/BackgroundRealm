import UIKit
import RealmSwift
import BackgroundRealm


class ViewController: UIViewController
{
    private let realm = try! Realm()
    private var token: NotificationToken?

    private func bindUI(_ object: DummyObject?) {
        guard let text = object?.text, text.isEmpty == false else {
            mainLabel.text = "No objects in the database"
            return
        }
        mainLabel.text = text
    }

    @IBOutlet weak var mainLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        token = realm.objects(DummyObject.self).observe { [weak self] (change) in
            switch change {
            case let .error(error): print("\(error)")
            case let .initial(results), let .update(results, _, _, _):
                self?.bindUI(results.first)
                print("UI UPDATED; isMainThread: \(Thread.current == Thread.main)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("NO OBJECTS IN THE REALM YET; isMainThread: \(Thread.current == Thread.main)")

        let realm = self.realm
        print("ADDING AN OBJECT TO THE REALM; isMainThread: \(Thread.current == Thread.main)")

        realm.writeInBackground { (result) in
            switch result {
            case let .failure(error): print("\(error)")
            case let .success(backgroundRealm):

                let obj = DummyObject()
                obj.text = "This text was created in a background thread"
                backgroundRealm.add(obj)
                print("OBJECT ADDED TO THE REALM; isMainThread: \(Thread.current == Thread.main)")
            }
        }
    }
}

