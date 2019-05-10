//
//  ViewController.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit
import FRZDatabaseViewMapper

class ViewController: UIViewController, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static private let shouldUseTableView = false

    private let dataSource = DataSource()
    private var tableView: UITableView? = nil
    private var collectionView: UICollectionView? = nil

    override func loadView() {
        let initialFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        if ViewController.shouldUseTableView {
            let tableView = UITableView.init(frame: initialFrame, style: .grouped)
            self.tableView = tableView
            self.view = tableView
        } else {
            let layout = UICollectionViewFlowLayout()
            let collectionView = UICollectionView.init(frame: initialFrame, collectionViewLayout: layout)
            self.collectionView = collectionView
            self.view = collectionView
        }
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.view == self.tableView {
            tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell_ID")
            dataSource.view = tableView!
            tableView?.dataSource = self
        } else {
            collectionView?.backgroundColor = .white
            collectionView?.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell_ID")
            collectionView?.register(CollectionSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "section_header")
            dataSource.view = collectionView!
            collectionView?.delegate = self
            collectionView?.dataSource = self
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dataSource.startUpdatingData()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_ID", for: indexPath)
        let holder = dataSource.itemAtIndexPath(indexPath)
        cell.textLabel?.text = holder.identifier + " " + String(holder.value)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.groupAtSection(section)
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell_ID", for: indexPath) as! CollectionViewCell
        let holder = dataSource.itemAtIndexPath(indexPath)
        cell.textLabel.text = holder.identifier + " " + String(holder.value)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "section_header", for: indexPath) as! CollectionSectionHeaderView
        header.textLabel.text = dataSource.groupAtSection(indexPath.section)
        return header
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 55)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 45)
    }

}

