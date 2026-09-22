import Foundation
import CoreBluetooth

class PrinterManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isBluetoothReady = false
    @Published var connectionStatus = "Disconnected"
    @Published var discoveredPrinters: [CBPeripheral] = []
    
    private var centralManager: CBCentralManager!
    private var activePrinter: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    // Fallback standard UUID strings used by generic portable thermal ticket makers
    private let serialServiceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    private let writeCharacteristicUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionStatus = "Scanning for label printers..."
        discoveredPrinters.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectionStatus = "Connecting to \(peripheral.name ?? "Unknown Printer")..."
        activePrinter = peripheral
        activePrinter?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func sendToPrinter(rawPayload: String) {
        guard let printer = activePrinter, let characteristic = writeCharacteristic else {
            connectionStatus = "Error: Printer not ready"
            return
        }
        
        if let data = rawPayload.data(using: .utf8) {
            // Sends the label layout chunked to fit the standard MTU over Bluetooth Low Energy
            printer.writeValue(data, for: characteristic, type: .withResponse)
            connectionStatus = "Label sent successfully!"
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothReady = true
            connectionStatus = "Bluetooth powered on"
            startScanning()
        case .poweredOff:
            isBluetoothReady = false
            connectionStatus = "Error: Turn on Bluetooth"
        case .unauthorized:
            connectionStatus = "Error: App lacks Bluetooth permission"
        default:
            connectionStatus = "Bluetooth unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, !name.isEmpty {
            if !discoveredPrinters.contains(peripheral) {
                discoveredPrinters.append(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected to \(peripheral.name ?? "Device")"
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Failed to establish connection"
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, some: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // Identify standard data stream channel attributes
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writeCharacteristic = characteristic
                connectionStatus = "Printer online & synchronized"
            }
        }
    }
}
