//
//  HJMessageVC.swift
//  中心设备
//
//  Created by Mr.H on 2017/8/24.
//  Copyright © 2017年 Mr.H. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

@available(iOS 10.0, *)
class HJMessageVC: UIViewController {

    var tableView: UITableView = UITableView()
    
    var textFiled: UITextField = UITextField()
    
    var disposeBag = DisposeBag()
    
    var cbCentral: HJCBCenterBridge!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        
        self.creatBtn()
        
        self.creatTableView()
  
    }

    /// 创建tableview
    func creatTableView() {
        
        self.view.addSubview(self.tableView)
        
        let height = UIScreen.main.bounds.height - 400
        
        self.tableView.snp.makeConstraints {
            
            $0.height.equalTo(height)
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(60)
            
        }
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
       
        self.cbCentral.dataArray.asObservable().bind(to: self.tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)){ (row, element, cell) in
            
            if element.type == .Type_my {
                
                cell.textLabel?.textAlignment = .right
                
            }else {
                
                cell.textLabel?.textAlignment = .left
                
            }
            
                cell.textLabel?.text = element.message
            
            }.addDisposableTo(disposeBag)
        
    }
    
    /// 创建扫描设备按钮
    func creatBtn() {
        
        let btn = UIButton()
        
        btn.backgroundColor = UIColor.brown
        
        btn.setTitle("返回", for: .normal)
        
        btn.addTarget(self, action: #selector(touchBtn), for: .touchUpInside)
        
        self.view.addSubview(btn)
        
        btn.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.width.equalTo(60)
            $0.top.equalToSuperview().offset(20)
            $0.height.equalTo(40)
        }
        
        self.textFiled.backgroundColor = UIColor.orange
        
        self.view.addSubview(textFiled)
        
        textFiled.placeholder = "请输入要发送的信息"
        
        textFiled.delegate = self

        textFiled.snp.makeConstraints {
            $0.left.equalTo(btn.snp.right)
            $0.right.equalToSuperview()
            $0.top.bottom.equalTo(btn)
        }
        
    }
    
    /// 开启扫描外围设备
    func touchBtn() {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.cbCentral.disconnect()
        
    }

}

@available(iOS 10.0, *)
extension HJMessageVC: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.cbCentral.sendMessage(textFiled.text ?? "")
        
        return true
        
    }

}
