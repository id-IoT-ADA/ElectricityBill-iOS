//
//  MQTT.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 30/06/26.
//

import Foundation
import CocoaMQTT
import Combine

class MQTTManager: ObservableObject {
    private var mqtt: CocoaMQTT?
    @Published var connectionStatus: String = "Disconnected"
    
    func connect() {
        let clientID = "iOSClient_" + UUID().uuidString
        mqtt = CocoaMQTT(clientID: clientID, host: "broker.hivemq.com", port: 1883)
        
//        mqtt?.username = "your_secure_username"
//        mqtt?.password = "your_secure_password"
//        
//        mqtt?.enableSSL = true
        
//        let allowUntrustedCertificates = false
//        mqtt?.sslSettings = [
//            "kCFStreamSSLValidatesCertificateChain": allowUntrustedCertificates as NSObject
//        ]
        
        mqtt?.keepAlive = 60
        mqtt?.autoReconnect = true
        
        mqtt?.didConnectAck = { [weak self] _, ack in
            DispatchQueue.main.async {
                if ack == .accept {
                    self?.connectionStatus = "Connected"
                    self?.subscribe(to: "home/livingroom/temperature")
                } else {
                    self?.connectionStatus = "Failed: \(ack)"
                }
            }
        }
        
        mqtt?.didReceiveMessage = { _, message, _ in
            let payload = message.string ?? ""
            print("Received message: \(payload) on topic: \(message.topic)")
        }
        
        _ = mqtt?.connect()
    }
    
    func subscribe(to topic: String) {
        mqtt?.subscribe(topic, qos: .qos1)
    }
    
    func publish(message: String, to topic: String) {
        mqtt?.publish(topic, withString: message, qos: .qos1)
    }
    
    func disconnect() {
        mqtt?.disconnect()
    }
}
