//
//  StoreHoldersOperation.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit
import YapDatabase

class StoreHoldersOperation: Operation {

    private let holders: [Holder]
    private let connection: YapDatabaseConnection

    init(holders: [Holder], connection: YapDatabaseConnection) {
        self.holders = holders
        self.connection = connection
        super.init()
    }

    override func main() {
        connection.asyncReadWrite { (transaction) in
            var allKeys = Set(transaction.allKeys(inCollection: DatabaseManager.Collections.default))

            for holder in self.holders {
                transaction.setObjectIfChanged(holder, forKey: holder.identifier, inCollection: DatabaseManager.Collections.default)
                allKeys.remove(holder.identifier)
            }

            transaction.removeObjects(forKeys: Array(allKeys), inCollection: DatabaseManager.Collections.default)
        }
    }

}
