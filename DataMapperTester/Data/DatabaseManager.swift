//
//  DatabaseManager.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import Foundation
import YapDatabase

let UIDatabaseConnectionDidUpdateNotification = "UIDatabaseConnectionDidUpdateNotification"

class DatabaseManager: NSObject {

    struct Collections {
        static let `default` = "Default"
    }

    static let shared: DatabaseManager = DatabaseManager(url: DatabaseManager.databaseFileURL)

    let database: YapDatabase
    let uiConnection: YapDatabaseConnection
    let rwConnection: YapDatabaseConnection

    // MARK: - File management

    static var databaseExists: Bool {
        return FileManager.default.fileExists(atPath: self.databaseFileURL.path)
    }

    static var databaseFolderExists: Bool {
        return FileManager.default.fileExists(atPath: self.databaseFolderURL.path)
    }

    static var databaseFileURL: URL {
        let databaseFolderURL = self.databaseFolderURL
        return databaseFolderURL.appendingPathComponent("DatabaseMapperTest.sqlite")
    }

    private static var databaseFolderURL: URL {
        let libraryURL = self.applicationLibraryDirectory
        return libraryURL.appendingPathComponent("Database", isDirectory: true)
    }

    private static var applicationLibraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }

    init(url: URL) {
        if !DatabaseManager.databaseExists && !DatabaseManager.databaseFolderExists {
            do {
                try FileManager.default.createDirectory(at: DatabaseManager.databaseFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                abort()
            }
        }

        self.database = YapDatabase.init(path: url.path)!
        self.rwConnection = self.database.newConnection()
        self.uiConnection = self.database.newConnection()
        super.init()
        #if DEBUG
        self.uiConnection.permittedTransactions = [.YDB_AnyReadTransaction, .YDB_MainThreadOnly]
        #endif
        self.uiConnection.beginLongLivedReadTransaction()


        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseModified(_:)), name: NSNotification.Name.YapDatabaseModified, object: self.database)
    }

    @objc fileprivate func yapDatabaseModified(_ notification: NSNotification) {
        let notifications = self.uiConnection.beginLongLivedReadTransaction()
        let userInfo = ["notifications": notifications]
        NotificationCenter.default.post(name: NSNotification.Name(UIDatabaseConnectionDidUpdateNotification), object: self.uiConnection, userInfo: userInfo)
    }

    func isViewRegistered(_ view: String) -> Bool {
        var isRegistered = false
        self.uiConnection.read { (transation) in
            isRegistered = transation.extension(view) != nil
        }
        return isRegistered
    }

}

extension YapDatabaseReadWriteTransaction {

    @discardableResult func setObjectIfChanged(_ object: AnyObject, forKey key: String, inCollection collection: String) -> Bool {
        if let currentObject = self.object(forKey: key, inCollection: collection) {
            if !object.isEqual(currentObject) {
                self.setObject(object, forKey: key, inCollection: collection)
                return true
            }
            return false
        }
        self.setObject(object, forKey: key, inCollection: collection)
        return true
    }

}
