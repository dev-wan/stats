//
//  BatteryReader.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 14/06/2019.
//  Copyright © 2019 Serhiy Mytrovtsiy. All rights reserved.
//

import Foundation
import IOKit.ps

class BatteryReader: Reader {
    var usage: Observable<Float>!
    var available: Bool = false
    var updateTimer: Timer!
    
    init() {
        self.usage = Observable(0)
        read()
    }
    
    func start() {
        if updateTimer != nil {
            return
        }
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(read), userInfo: nil, repeats: true)
    }
    
    func stop() {
        if updateTimer == nil {
            return
        }
        updateTimer.invalidate()
        updateTimer = nil
    }
    
    @objc func read() {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]
        self.available = psList.count != 0
        
        for ps in psList {
            if let psDesc = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
                let isCharging = (psDesc[kIOPSIsChargingKey] as? Bool)
                var cap: Float = Float(psDesc[kIOPSCurrentCapacityKey] as! Int) / 100
                
                if !isCharging! {
                    cap = 0 - cap
                }
                
                self.usage << Float(cap)
            }
        }
    }
}
