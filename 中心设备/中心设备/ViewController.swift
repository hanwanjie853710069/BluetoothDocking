//
//  ViewController.swift
//  中心设备
//
//  Created by Mr.H on 2017/8/24.
//  Copyright © 2017年 Mr.H. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxCocoa
import SnapKit

@available(iOS 10.0, *)
class ViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    
    var tableView: UITableView = UITableView()
    
    /// 中心设备适配器
    lazy var cbCentral: HJCBCenterBridge = { return HJCBCenterBridge() }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.creatTableView()
        
        self.creatBtn()
        
    }
    
    
    /// 创建tableview
    func creatTableView() {
        
        self.view.addSubview(self.tableView)
        
        self.tableView.snp.makeConstraints {
            
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(100)
            
        }
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.cbCentral.peripherals.asObservable().bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)){ (row, element, cell) in
            
            cell.textLabel?.text = element.peripheral.name ?? "没有设备名称"
            
            }.addDisposableTo(disposeBag)
        
        
        self.tableView.rx.modelSelected(PeripheralModel.self).subscribe(onNext: { [unowned self] model in
            
            self.cbCentral.connectionPeripherals(model.peripheral)
            
            let vc = HJMessageVC()
            
            vc.cbCentral = self.cbCentral
            
            self.present(vc, animated: true, completion: nil)
            
        }).addDisposableTo(disposeBag)
        
    }
    
    
    /// 创建扫描设备按钮
    func creatBtn() {
        
        let btn = UIButton()
        
        btn.backgroundColor = UIColor.brown
        
        btn.setTitle("扫描设备", for: .normal)
        
        btn.addTarget(self, action: #selector(touchBtn), for: .touchUpInside)
        
        self.view.addSubview(btn)
        
        btn.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(20)
            $0.height.equalTo(50)
        }
        
    }
    
    /// 开启扫描外围设备
    func touchBtn() {
        
        self.cbCentral.scanningPeripherals()
        
    }
    
}






