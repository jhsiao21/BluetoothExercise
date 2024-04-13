//
//  ViewController.swift
//  BluetoothExercise
//
//  Created by LoganMacMini on 2024/4/13.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    private let viewModel = ViewModel()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .systemBackground
        table.separatorStyle = .none
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
                
        layout()
        configureNavbar()
        viewModel.bluetooth.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    private func layout() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 0),
            tableView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 0),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: tableView.trailingAnchor, multiplier: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureNavbar() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "bluetooth_disabled_icon")?.withRenderingMode(.alwaysOriginal),
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(stopScanBluetoothHandle))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "bluetooth_search_icon")?.withRenderingMode(.alwaysOriginal),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(startScanBluetoothHandle))
        
    }
    
    @objc private func stopScanBluetoothHandle() {
        print("bluetoothHandle")
        viewModel.stopScan()
        viewModel.bluetooth.disconnect()
        self.tableView.reloadData()
    }
    
    @objc private func startScanBluetoothHandle() {
        print("bluetoothHandle")
        viewModel.startScan()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        guard let deviceName = viewModel.list[indexPath.row].peripheral.name else { return UITableViewCell() }
        cell.textLabel?.text = deviceName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt:\(indexPath.row)")
        
        let peripheral = viewModel.list[indexPath.row].peripheral
        
        viewModel.bluetooth.connect(peripheral)
    }
}

extension ViewController: BLEMangerDelegate {
    func state(state: BLEManager.State) {
        print("state: \(state)")
    }
    
    func list(list: [BLEManager.Peripheral]) {
        print("list count:\(list.count)")
        viewModel.list = list
        self.tableView.reloadData()
    }
    
    func value(data: Data) {
        
    }
    
    
}
