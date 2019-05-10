//
//  ViewController.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    private let dataSource = DataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell_ID")
        dataSource.view = tableView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dataSource.startUpdatingData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_ID", for: indexPath)
        let holder = dataSource.itemAtIndexPath(indexPath)
        cell.textLabel?.text = holder.identifier + " " + String(holder.value)
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.groupAtSection(section)
    }

}

