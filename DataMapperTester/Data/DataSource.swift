//
//  DataSource.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit
import FRZDatabaseViewMapper
import YapDatabase

class DataSource: NSObject, FRZDatabaseViewMapperDelegate {

    private static let reloadInterval: TimeInterval = 4

    var view: FRZDatabaseMappable? {
        didSet {
            if let view = view {
                viewMapper.view = view
            }
        }
    }
    private let operationQueue = OperationQueue()
    private let databaseConnection = DatabaseManager.shared.database.newConnection()
    private let databaseViewName = "default_view"
    private let viewMapper: FRZDatabaseViewMapper
    private var refreshTimer: Timer!

    override init() {
        viewMapper = FRZDatabaseViewMapper(connection: DatabaseManager.shared.uiConnection, updateNotificationName: NSNotification.Name(rawValue: UIDatabaseConnectionDidUpdateNotification))

        super.init()

        viewMapper.delegate = self
        if DatabaseManager.shared.isViewRegistered(databaseViewName) {
            initializeViewMappings()
        } else {
            registerDatabaseView()
        }

//        NotificationCenter.default.addObserver(self, selector: #selector(uiConnectionDidUpdate(notification:)), name: NSNotification.Name(rawValue: UIDatabaseConnectionDidUpdateNotification), object: nil)
    }

    // MARK - Database

    private func initializeViewMappings() {
        let mappings = YapDatabaseViewMappings(groupFilterBlock: { (_, _) -> Bool in
            return true
        }, sortBlock: { (group1, group2, transaction) -> ComparisonResult in
            let id1: Int = Int(group1)!
            let id2: Int = Int(group2)!
            if id1 > id2 {
                return .orderedAscending
            }
            if id1 < id2 {
                return .orderedDescending
            }
            return .orderedSame
        }, view: databaseViewName)
        mappings.setIsDynamicSectionForAllGroups(true)
        self.viewMapper.activeViewMappings = [mappings]
    }

    private func registerDatabaseView() {
        let whitelist = YapWhitelistBlacklist(whitelist: [DatabaseManager.Collections.default])
        let options = YapDatabaseViewOptions()
        options.allowedCollections = whitelist
        let view = YapDatabaseAutoView(grouping: grouping, sorting: sorting, versionTag: "4", options: options)

        DatabaseManager.shared.database.asyncRegister(view, withName: databaseViewName) { (_) in
            self.initializeViewMappings()
        }
    }

    private let sorting: YapDatabaseViewSorting = {
        return YapDatabaseViewSorting.withObjectBlock({ (transaction, group, collection1, key1, object1, collection2, key2, object2) -> ComparisonResult in
            guard let holder1 = object1 as? Holder, let holder2 = object2 as? Holder else {
                return .orderedSame
            }
            let id1: Int = Int(holder1.identifier)!
            let id2: Int = Int(holder2.identifier)!
            if id1 > id2 {
                return .orderedAscending
            }
            if id1 < id2 {
                return .orderedDescending
            }
            return .orderedSame
        })
    }()

    private let grouping: YapDatabaseViewGrouping = {
        return YapDatabaseViewGrouping.withObjectBlock({ (transaction, collection, key, object) -> String? in
            guard let holder = object as? Holder else {
                return nil
            }
            return String(Int(holder.value / 10))
        })
    }()

    @objc private func uiConnectionDidUpdate(notification: Notification) {
        databaseConnection.read { (transaction) in
            print(transaction.allKeys(inCollection: DatabaseManager.Collections.default))
        }
    }

    // MARK - Data

    @objc private func generateData() {
        DispatchQueue.global().async {
            let operation = HolderGenerationOperation(topCap: 100, fill: 50)
            self.operationQueue.addOperations([operation], waitUntilFinished: true)
            self.storeHolders(operation.holders)
        }
    }

    private func storeHolders(_ holders: [Holder]) {
        let operation = StoreHoldersOperation(holders: holders, connection: databaseConnection)
        operationQueue.addOperation(operation)
    }

    // API

    func startUpdatingData() {
        self.refreshTimer = Timer.scheduledTimer(timeInterval: DataSource.reloadInterval, target: self, selector: #selector(generateData), userInfo: nil, repeats: true)
    }

    func numberOfSections() -> Int {
        return Int(viewMapper.numberOfSections())
    }

    func numberOfItemsInSection(_ section: Int) -> Int {
        return Int(viewMapper.numberOfItems(inSection: UInt(section)))
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Holder {
        return viewMapper.object(at: indexPath) as! Holder
    }

    func groupAtSection(_ section: Int) -> String {
        return viewMapper.group(forSection: UInt(section))
    }

}
