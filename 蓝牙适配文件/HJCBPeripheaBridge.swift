//
//  HJCBPeripheaBridge.swift
//  外围设备
//
//  Created by 王木木 on 2017/8/27.
//  Copyright © 2017年 Mr.H. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

class HJCBPeripheaBridge: HJPeripheralAdapter {
    
    /// 数据源数组
    var dataArray: Variable<[MessageModel]> = Variable<[MessageModel]>([])
    
    override init() {
        super.init()
        
        self.message.asObservable().subscribe(onNext: { [unowned self] model in
            
            if model.type != .Type_defale {
                
                self.dataArray.value.append(model)
                
            }
            
        }).addDisposableTo(disposeBag)
        
    }
    
}
