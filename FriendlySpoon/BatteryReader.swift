import Foundation
import Combine
import CoreBluetooth
import AppKit

private let batteryServiceUUID = CBUUID(string: "180F")
private let batteryLevelCharUUID = CBUUID(string: "2A19")
private let lastSelectedKey = "lastSelectedPeripheralID"
private let pollInterval: TimeInterval = 60

final class BatteryReader: NSObject, ObservableObject {
    @Published var availablePeripherals: [CBPeripheral] = []
    @Published var status: String = "Starting Bluetooth…"
    @Published var selectedPeripheralID: UUID?
    @Published var isConnected: Bool = false
    @Published var leftPercent: Int = 0
    @Published var rightPercent: Int = 0

    private var central: CBCentralManager!
    private var selectedPeripheral: CBPeripheral?
    private var pollTimer: Timer?

    // Upstream hack: keyboard fires the battery callback twice in a row,
    // first for the left half then the right. Flip-flop tracks which one we're on.
    // Known fragile — replace with per-characteristic identity later.
    private var nextReadingIsRightHalf = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
        observeWorkspace()
        startPolling()
    }

    // MARK: - Public actions

    func refresh() {
        guard central.state == .poweredOn else { return }
        availablePeripherals = central.retrieveConnectedPeripherals(
            withServices: [batteryServiceUUID]
        )
        if selectedPeripheralID == nil {
            status = "Found \(availablePeripherals.count) keyboard(s)"
        }
    }

    func select(_ peripheral: CBPeripheral) {
        selectedPeripheral = peripheral
        selectedPeripheralID = peripheral.identifier
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastSelectedKey)
        isConnected = false
        leftPercent = 0
        rightPercent = 0
        nextReadingIsRightHalf = false
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
        status = "Connecting to \(peripheral.name ?? "keyboard")…"
    }

    func readBattery() {
        guard let p = selectedPeripheral else { return }
        switch p.state {
        case .connected:    p.discoverServices([batteryServiceUUID])
        case .disconnected: central.connect(p, options: nil)
        default:            break
        }
    }

    // MARK: - Auto-reconnect

    private func restoreLastSelected() {
        guard
            let str = UserDefaults.standard.string(forKey: lastSelectedKey),
            let uuid = UUID(uuidString: str),
            let p = central.retrievePeripherals(withIdentifiers: [uuid]).first
        else { return }
        NSLog("[BatteryReader] restoring last device: \(p.name ?? "?")")
        select(p)
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: pollInterval, repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard central.state == .poweredOn else { return }
        refresh()
        guard let p = selectedPeripheral else { return }
        switch p.state {
        case .connected:    p.discoverServices([batteryServiceUUID])
        case .disconnected: central.connect(p, options: nil)
        default:            break
        }
    }

    private func observeWorkspace() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didWakeNotification,
                       object: nil, queue: .main) { [weak self] _ in
            NSLog("[BatteryReader] system woke — retrying")
            self?.tick()
        }
    }
}

extension BatteryReader: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let label: String
        switch central.state {
        case .poweredOn:    label = "poweredOn"
        case .poweredOff:   label = "poweredOff"
        case .unauthorized: label = "unauthorized"
        case .unsupported:  label = "unsupported"
        case .resetting:    label = "resetting"
        case .unknown:      label = "unknown"
        @unknown default:   label = "other(\(central.state.rawValue))"
        }
        NSLog("[BatteryReader] CB state: \(label)")
        if central.state == .poweredOn {
            refresh()
            if selectedPeripheralID == nil {
                restoreLastSelected()
            } else if let p = selectedPeripheral, p.state == .disconnected {
                central.connect(p, options: nil)
            }
        } else {
            status = "BT: \(label)"
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("[BatteryReader] connected: \(peripheral.name ?? "?")")
        isConnected = true
        readBattery()
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        NSLog("[BatteryReader] disconnected: \(peripheral.name ?? "?")")
        // Queue a reconnect — CB will fire didConnect once peripheral is in range again.
        if peripheral.identifier == selectedPeripheralID {
            isConnected = false
            central.connect(peripheral, options: nil)
            status = "Disconnected. Waiting…"
        }
    }
}

extension BatteryReader: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == batteryServiceUUID {
            peripheral.discoverCharacteristics([batteryLevelCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard service.uuid == batteryServiceUUID else { return }
        for char in service.characteristics ?? [] where char.uuid == batteryLevelCharUUID {
            peripheral.readValue(for: char)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard characteristic.uuid == batteryLevelCharUUID,
              let pct = characteristic.value?.first
        else { return }

        if nextReadingIsRightHalf {
            rightPercent = Int(pct)
        } else {
            leftPercent = Int(pct)
        }
        nextReadingIsRightHalf.toggle()
        status = "L \(leftPercent)%  R \(rightPercent)%"
        NSLog("[BatteryReader] battery update: L=\(leftPercent) R=\(rightPercent)")
    }
}
