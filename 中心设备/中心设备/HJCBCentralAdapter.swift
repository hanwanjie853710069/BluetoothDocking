//
//  HJCBCentralAdapter.swift
//  中心设备
//
//  Created by Mr.H on 2017/8/24.
//  Copyright © 2017年 Mr.H. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

/// 蓝牙中心设备适配器
@available(iOS 10.0, *)
class HJCBCentralAdapter: NSObject {
    
    /// 读写服务的uuid
    let SERVICE_UUID = "CDD1"
    
    /// 读特征uuid
    let CHARACTERISTIC_UUIDREAD  = "CDD2"
    
    /// 中心设备管理器
    var centralManager: CBCentralManager!
    
    /// 外围设备数组
    var peripherals: Variable<[PeripheralModel]> = Variable<[PeripheralModel]>([])
    
    /// 当前选中的外围设备
    var selectPeripheral: CBPeripheral!
    
    /// 当前选中的外设设备特征特征  读写特征
    var characteristic: CBCharacteristic!
    
    /// 当前蓝牙状态
    var state: Variable<CBManagerState> = Variable<CBManagerState>(.unknown)
    
    /// 当前与外围设备的连接状态
    var connectionType: Variable<ConnectionType> = Variable<ConnectionType>(.Type_disconnect)
    
    /// 交互消息
    var message:Variable<MessageModel> = Variable<MessageModel>(MessageModel())
    
    /// 中心设备向外围设备写数据状态
    var writeSubscribeType: Variable<SubscribeType> = Variable<SubscribeType>(.Type_defaule)
    
    override init() {
        super.init()
        
        /// 创建中心设备管理器 会回调centralManagerDidUpdateState
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    
    /// 扫描外围设备
    ///
    /// - Returns: 蓝牙是否开启
    func scanningPeripherals() -> Bool {
        
        if self.state.value == .poweredOn {
            
            /// 根据服务uuid来扫描外围设备 如果withServices为nil则扫描全部外围设备
            self.centralManager.scanForPeripherals(withServices: [CBUUID(string: SERVICE_UUID)], options: nil)
            
            return true
            
        }else {
            
            print("蓝牙未开启")
            
            return false
            
        }
        
    }
    
    /// 连接外围设备
    func connectionPeripherals(_ peripheral: CBPeripheral) {
        
        self.selectPeripheral = peripheral
        
        self.centralManager.connect(peripheral, options: nil)
        
    }
    
}

@available(iOS 10.0, *)
extension HJCBCentralAdapter: CBCentralManagerDelegate,CBPeripheralDelegate {
    
    /// 当前蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .unknown:      self.state.value = .unknown // 未知
            
        case .resetting:    self.state.value = .resetting // 重置中
            
        case .unsupported:  self.state.value = .unsupported // 不支持
            
        case .unauthorized: self.state.value = .unauthorized // 未验证
            
        case .poweredOff:   self.state.value = .poweredOff // 未启动
            
        case .poweredOn:    self.state.value = .poweredOn // 可用
            
        }
        
    }
    
    ///  扫描到的外围设备的回调
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let model =   PeripheralModel(central: central, peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        
        if (self.peripherals.value.filter {  $0.peripheral.isEqual(peripheral) }).first == nil {
            
            self.peripherals.value.append(model)
            
        }
        
    }
    
    /// 连接外围设备成功的回调
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        /// 连接设备成功停止扫描
        self.centralManager.stopScan()
        
        /// 设置代理
        peripheral.delegate = self
        
        /// 根据UUID来寻找服务
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID),CBUUID(string: SERVICE_UUID)])
        
        self.connectionType.value = .Type_succeed
        
        print("连接成功")
        
    }
    
    /// 连接外围设备失败的回调
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("连接外围设备失败的回调")
        
        self.connectionType.value = .Type_fail
        
    }
    
    /// 与外围设备断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("与外围设备断开连接")
        
        self.connectionType.value = .Type_disconnect
        
        /// 重新连接外围设备
        /// central.connect(peripheral, options: nil)
        
    }
    
    
    /// mark - CBPeripheralDelegate
    /// 发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        /// 遍历所有服务
        peripheral.services?.forEach({
            
            /// 打印所有哦服务
            print("所有服务\($0)")
            
            /// 判断是不是我们要的那个服务
            if $0.uuid.isEqual(CBUUID(string: SERVICE_UUID)) {
                
                /// 根据特征id查找我们要的特征
                peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_UUIDREAD)], for: $0)
                
            }
            
        })
        
        
    }
    
    /// 根据获取特征的回调
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        
        /// 遍历所有的特征
        /// 从外设开发人员那里拿到不同特征的UUID，
        /// 不同特征做不同事情，比如有读取数据的特征，也有写入数据的特征
        service.characteristics?.forEach({
            
            if $0.uuid.isEqual(CBUUID(string: CHARACTERISTIC_UUIDREAD)) {
                
                /// 这里只获取一个特征
                self.characteristic = $0
                
                /// 直接读取这个特征数据
                peripheral.readValue(for: $0)
                
                /// 订阅通知
                peripheral.setNotifyValue(true, for: $0)
                
            }
            
            print("所有特征\($0)")
            
        })
        
    }
    
    
    /// 订阅状态的改变回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil { print("订阅失败\(String(describing: error))") }
        
        if characteristic.isNotifying { print("订阅成功") }
        
        if !characteristic.isNotifying { print("取消订阅") }
        
    }
    
    /// 接收到数据回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        /// 拿到外设发过来的数据
        let data = characteristic.value
        
        if data == nil { return }
        
        let dict = self.jsonToDict(data: data!)
        
        let str = dict["message"] ?? ""
        
        self.message.value = MessageModel(mg: str, type: .Type_other)
        
    }
    
    /// 写入数据回调
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            
            self.writeSubscribeType.value = .Type_failure
            
            print(error!)
            
            return
        }
        
        self.writeSubscribeType.value = .Type_successful
        
        print("回调写入成功")
        
    }
    
    /// 读取数据  效果和外围设备写入是一个概念 在此屏蔽
    private func readData() {
        
        self.selectPeripheral.readValue(for: self.characteristic)
        
    }
    
    /// 写入数据
    func sendMessage(_ message: String) {
        
        if message.isEmpty { return }
        
        /// 用data类型写入
        let data = self.stringToJson(PersonType: "Type_other", message: message, x: "", y: "")
        
        /// 根据特征来写入
        self.selectPeripheral.writeValue(data, for: self.characteristic, type: .withResponse)
        
        self.message.value = MessageModel(mg: message, type: .Type_my)
        
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
        
        guard let dict = jsonArr else { return ["PersonType" :"Type_defale","x":"","y":"","message" : ""] }
        
        return dict
        
    }
    
    /// 断开蓝牙连接
    func disconnect() {
        
        self.centralManager.cancelPeripheralConnection(self.selectPeripheral)
        
        self.selectPeripheral = nil
        
        self.characteristic = nil
        
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


/// subscribe订阅写入状态
enum SubscribeType {
    
    ///  默认
    case Type_defaule
    
    /// 成功
    case Type_successful
    
    ///  失败
    case Type_failure
    
}
