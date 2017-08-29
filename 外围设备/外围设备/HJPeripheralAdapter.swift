//
//  HJPeripheralAdapter.swift
//  外围设备
//
//  Created by Mr.H on 2017/8/24.
//  Copyright © 2017年 Mr.H. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

/// 蓝牙外围设备适配器
@available(iOS 10.0, *)
class HJPeripheralAdapter: NSObject {
    
    /// 读写服务的uuid
    let SERVICE_UUID = "CDD1"
    
    /// 读特征uuid
    let CHARACTERISTIC_UUIDREAD  = "CDD2"
    
    /// 外围设备中心管理器
    var peripheralManager: CBPeripheralManager!
    
    /// 特征
    var characteristic: CBMutableCharacteristic!
    
    /// 当前蓝牙状态
    var state: Variable<CBManagerState> = Variable<CBManagerState>(.unknown)
    
    /// 交互消息数组
    var message:Variable<MessageModel> = Variable<MessageModel>(MessageModel())
    
    /// 外围设备订阅状态
    var peripheralSubscribeType: Variable<SubscribeType> = Variable<SubscribeType>(.Type_defaule)
    
    override init() {
        super.init()
        
        let queue = DispatchQueue.global()
        
        // 创建外设管理器，会回调peripheralManagerDidUpdateState方法
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
        
    }
    
    /// 创建服务和特征
    func setupServiceAndCharacteristics() {
        
        /// 创建服务
        let serviceID = CBUUID(string: SERVICE_UUID)
        
        let service = CBMutableService(type: serviceID, primary: true)
        
        ///创建服务中的特征
        let characteristicID = CBUUID(string: CHARACTERISTIC_UUIDREAD)
        
        let characteristic = CBMutableCharacteristic(type: characteristicID,
                                                     properties: [.write, .notify],
                                                     value: nil,
                                                     permissions: [.writeable ])
        
        /// 添加读写特征到服务
        service.characteristics = [characteristic]
        
        /// 添加服务到管理
        self.peripheralManager.add(service)
        
        /// 为了手动给中心设备发数据保存 特征
        self.characteristic = characteristic
        
    }
    
    /// 发送广播 返回蓝牙状态
    @discardableResult
    func sendBroadcast() -> Bool {
        
        if self.state.value == .poweredOn {
            
            /// 创建服务和特征
            self.setupServiceAndCharacteristics()
            
            /// 根据服务的uuid开始广播
            self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: SERVICE_UUID)]])
            
            return true
            
        }
        
        print("蓝牙未开启")
        
        return false
        
    }
    
}


@available(iOS 10.0, *)
extension HJPeripheralAdapter: CBPeripheralManagerDelegate {
    
    /** 判断手机蓝牙状态*/
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
            
        case .unknown:      self.state.value = .unknown // 未知
            
        case .resetting:    self.state.value = .resetting // 重置中
            
        case .unsupported:  self.state.value = .unsupported // 不支持
            
        case .unauthorized: self.state.value = .unauthorized // 未验证
            
        case .poweredOff:   self.state.value = .poweredOff // 未启动
            
        case .poweredOn:    self.state.value = .poweredOn // 可用
            
        }
        
    }
    
    /// 中心设备写入数据的时候回调
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        /// 写入数据得请求
        let request = requests.last
        
        peripheral.respond(to: request!, withResult: .success)
        
        DispatchQueue.main.async {
            
            let dict = self.jsonToDict(data: (request?.value)!)
            
            let str = dict["message"] ?? ""
            
            self.message.value = MessageModel(mg: str, x: "", y: "", type: .Type_other)
            
        }
        
    }
    
    /// 订阅成功回调
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        /// 订阅成功后停掉 广播
        self.peripheralManager.stopAdvertising()
        
        self.peripheralSubscribeType.value = .Type_subscribe
        
        print(#function)
        
    }
    
    /// 取消订阅的回调
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
        self.peripheralSubscribeType.value = .Type_cancelSubscribe
        
        print(#function)
        
        print("取消订阅")
        
    }
    
    /// 中心设备读取数据的回调 被动传输数据 暂时不用
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        /// 成功响应请求
        peripheral.respond(to: request, withResult: .success)
        
    }
    
    
    /// 通过固定的特征发送数据到中心设备
    ///
    /// - Parameter message: 发送的消息
    /// - Returns: 是否成功
    func sendMessage(_ message: String) -> Bool {
        
        let data = stringToJson(PersonType: "Type_other", message: message, x: "", y: "")
        
        let sendSuccess = self.peripheralManager.updateValue(data, for: self.characteristic, onSubscribedCentrals: nil)
        
        if sendSuccess {
            
             DispatchQueue.main.async {
            
            self.message.value = MessageModel(mg: message, x: "", y: "", type: .Type_my)
            
            }
             print("发送数据成功")
            
            return true
            
        }else {

             print("发送数据失败")
            
            return false
            
        }
        
    }
    
    /// 字符串转json 消息体
    ///
    /// - Parameters:
    ///   - PersonType: 消息类型
    ///   - message: 默认没有消息 Type_defale 自己发的消息 Type_my  对方的消息 Type_other
    ///   - x: 坐标轴
    ///   - y: 坐标轴
    /// - Returns:
    func stringToJson(PersonType:String, message: String, x: String, y: String) -> Data {
        
        let dict = ["PersonType":PersonType,"message":message, "x": x, "y":y]
        
        let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        
        return data!
        
    }
    
    /// json转字典
    ///
    /// - Parameter data:  消息体数据
    /// - Returns: 字典
    func jsonToDict(data: Data) -> [String: String] {
        
        let jsonArr = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: String]
        
        guard let dict = jsonArr else {
            return ["PersonType" :"Type_defale","x":"","y":"","message" : ""]
        }
        
        return dict
        
    }
    
}

/// 扫描到的外围设备数据
struct PeripheralModel {
    
    var central: CBCentralManager
    
    var peripheral: CBPeripheral
    
    var advertisementData: [String : Any]
    
    var rssi: NSNumber
    
}

/// 连接外围设备状态
enum ConnectionType {
    
    /// 正常
    case Type_succeed
    
    /// 失败
    case Type_fail
    
    /// 断开
    case Type_disconnect
    
}

/// 消息模型
struct MessageModel {
    
    /// 消息体
    var message: String
    
    /// 坐标x
    var x: String
    
    /// 坐标y
    var y: String
    
    /// 辨别是自己的数据还是对方的数据
    var type: PersonType
    
    init(mg:String = "", x:String = "", y: String = "" , type: PersonType = .Type_defale) {
        
        self.message = mg
        
        self.x = x
        
        self.y = y
        
        self.type = type
        
    }
    
}

/// 辨别身份
enum PersonType {
    
    /// 默认没有收到消息
    case Type_defale
    
    /// 自己
    case Type_my
    
    /// 对方
    case Type_other
}

/// subscribe订阅枚举
enum SubscribeType {

    /// 未订阅
    case Type_defaule
    
    /// 已经订阅
    case Type_subscribe
    
    /// 取消订阅
    case Type_cancelSubscribe

}


