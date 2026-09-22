import SwiftUI

struct ContentView: View {
    @StateObject private var sortingEngine = SortingEngine()
    @StateObject private var printerManager = PrinterManager()
    
    // Sample populated state simulating a detected scan artifact
    @State private var activeItem = CollectibleItem(
        title: "Wolverine Vol. 2 #1 (Classic Cover)",
        year: "1988",
        originSet: "X-Men Series",
        marketPrice: 79.95,
        isComicBook: true
    )
    
    @State private var showPrinterPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Camera Scanning Viewfinder Box
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)
                    Text("Align Card Art or Comic Barcode")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Live Rule-Engine Pipeline Diagnostics
                VStack(alignment: .leading, spacing: 14) {
                    Text("Automated Label Blueprint")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    Group {
                        Text("Detected Object: ").foregroundColor(.secondary) + Text(activeItem.title).bold()
                        Text("Release Year: ").foregroundColor(.secondary) + Text(activeItem.year)
                        Text("Parent Set: ").foregroundColor(.secondary) + Text(activeItem.originSet)
                        Text("Market Value: ").foregroundColor(.secondary) +
                        Text("£\(String(format: \"%.2f\", activeItem.marketPrice))")
                            .foregroundColor(.green)
                            .bold()
                    }
                    .font(.subheadline)
                    
                    // The dynamic calculation row demonstrating character extraction
                    HStack {
                        Text("Calculated Category Bin:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(sortingEngine.determineStorageSection(for: activeItem))
                            .font(.subheadline)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Hardware Connection Status Banner
                HStack {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(printerManager.connectionStatus.contains("online") ? .green : .orange)
                    Text("Hardware: \(printerManager.connectionStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action Controls Block
                VStack(spacing: 12) {
                    Button(action: { showPrinterPicker.toggle() }) {
                        Label("Configure Bluetooth Printer", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: executePrintSequence) {
                        Label("Print Adhesive Price Tag", systemImage: "printer.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Collector Scan Engine")
            .sheet(isPresented: $showPrinterPicker) {
                PrinterDiscoverySheet(printerManager: printerManager)
            }
        }
    }
    
    private func executePrintSequence() {
        let assignedBin = sortingEngine.determineStorageSection(for: activeItem)
        let formattedString = sortingEngine.generateLabelPayload(for: activeItem, section: assignedBin)
        
        // Push raw layout sequence directly down the CoreBluetooth data streams
        printerManager.sendToPrinter(rawPayload: formattedString)
    }
}

// Subview rendering detected regional devices in your vicinity
struct PrinterDiscoverySheet: View {
    @ObservedObject var printerManager: PrinterManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(printerManager.discoveredPrinters, id: \.identifier) { printer in
                Button(action: {
                    printerManager.connect(to: printer)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "printer")
                        Text(printer.name ?? "Generic BLE Thermal Printer")
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Local Printer")
            .toolbar {
                Button("Refresh") { printerManager.startScanning() }
            }
        }
    }
}
