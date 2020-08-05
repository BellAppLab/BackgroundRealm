//
//  DummyObject.swift
//  Example
//
//  Created by André Campana on 05/08/2020.
//  Copyright © 2020 Bell App Lab. All rights reserved.
//

import Foundation
import RealmSwift


@objcMembers
final class DummyObject: Object
{
    override class func primaryKey() -> String? {
        return "id"
    }

    dynamic var id: String = UUID().uuidString
    dynamic var text: String = ""
}
