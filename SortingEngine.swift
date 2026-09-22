import Foundation

// Struct defining any scanned Pokémon Card or Comic Book
struct CollectibleItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let year: String
    let originSet: String   // E.g., "Base Set", "X-Men Vol. 1"
    let marketPrice: Double
    let isComicBook: Bool   // True for comics, false for cards
}

class SortingEngine: ObservableObject {
    
    /// Processes metadata and determines the specific shelf/bin placement.
    func determineStorageSection(for item: CollectibleItem) -> String {
        let cleanTitle = item.title.lowercased()
        
        // Custom rule overrides: isolate Wolverine
        if cleanTitle.contains("wolverine") || item.originSet.lowercased().contains("wolverine") {
            return "Wolverine Standalone Section"
        }
        
        // Custom rule overrides: isolate Charizard cards specifically
        if cleanTitle.contains("charizard") {
            return "Charizard Vault"
        }
        
        // Default category fallback based on the parent source
        return item.originSet
    }
    
    /// Formats the raw text payload to instruct thermal label printers using standard layouts
    func generateLabelPayload(for item: CollectibleItem, section: String) -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        return """
        ================================
        \(section.uppercased())
        ================================
        Item: \(item.title)
        Year: \(item.year)
        Source: \(item.originSet)
        Scanned: \(timestamp)
        --------------------------------
        PRICE: £\(String(format: "%.2f", item.marketPrice))
        ================================
        """
    }
}
