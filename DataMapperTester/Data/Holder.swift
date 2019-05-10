//
//  Holder.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit

class Holder: NSObject, NSSecureCoding {

    let identifier: String
    let value: Int

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.identifier, forKey: "identifier")
        aCoder.encode(self.value, forKey: "value")
    }

    required init?(coder aDecoder: NSCoder) {
        self.identifier = aDecoder.decodeObject(forKey: "identifier") as! String
        self.value = aDecoder.decodeInteger(forKey: "value")
    }

    init(identifier: String, value: Int) {
        self.identifier = identifier
        self.value = value
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let holder = object as? Holder else {
            return false
        }
        return self.identifier == holder.identifier && self.value == holder.value
    }

}
