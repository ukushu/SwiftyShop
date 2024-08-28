# SwiftyShop

<img src="https://github.com/ukushu/SwiftyShop/blob/main/Logo_1024.png?raw=true" width="250">

Simple Shop library for iOS/macOS apps. Based on StoreKit2

## Supported OS >= 
* iOS 15.0
* macOS 12.0
* tvOS 15.0
* watchOS 8.0
* visionOS 1.0


## How to use

1. Create enum with products:
```swift
import Foundation
import SwiftyShop

public extension ProductID {
    var buyType : BuyType { BuyType(rawValue: id)! }
}

public enum BuyType : String, CaseIterable {
    case monthly = "com.myApp.singleMonth" // CHANGE ME!!!!
    case yearly  = "com.myApp.oneYear"   // CHANGE ME!!!!
    case forever = "com.myApp.buyForever"  // CHANGE ME!!!!
    
    // ADD HERE MORE IF NEEDED
}

extension BuyType {
    var productID : ProductID { ProductID(id: rawValue) }
    
    var monthsCount: String {
        switch self {
        case .forever:
            "∞"
        case .monthly:
            "1"
        case .yearly:
            "12"
        }
    }
    
    var periodName: String {
        switch self {
        case .forever:
            "Lifetime"
        case .yearly:
            "Months"
        case .monthly:
            "Month"
        }
    }
}

```

2. Add app delegate to your app:

```swift
import SwiftUI

@main
struct SwiftyShopHostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // THIS
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

```

Create AppDelegate for configure your store settings:

AppDelegate.swift:
```swift
import Foundation
import AppKit
import SwiftyShop

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        let products = BuyType.allCases.map{ $0.rawValue }
        
        let dictFilePath: String = ""//Set path for cache here 
        // as example: //Users/uks/Library/Containers/com.myApp/Data/.MySuperAppCache.cache
        
        SwiftyShopConfig.shared = SwiftyShopConfig(products: products, dictFilePath: dictFilePath, dictFilePass: "%write your password for cache file here%")
    }
}
```

3. Create your custom shop views

ShopView.swift
```swift
import Foundation
import SwiftUI
import SwiftyShop

class PricesViewModel : ObservableObject {
    @Published var type : BuyType = .yearly
    
    public static var shared = PricesViewModel()
    
    private init() { }
}


public struct MainView: View {
    @ObservedObject var model = PricesViewModel.shared
    
    public var body: some View {
        VStack{
            HStack(spacing: 12) {
                PriceBtn(type: .forever)
                
                PriceBtn(type: .yearly)
                
                PriceBtn(type: .monthly)
            }
            
            Button("buy selected") { model.type.productID.buy() }
            
            Button("restore purcnases") { MyShop.shared.restorePurchases() }
            
            Button("Privacy Policy") {  }
        }
    }
}
```

4. Create your product price view:

```swift
import Foundation
import SwiftUI
import SwiftyShop
import Essentials

struct PriceBtn: View {
    let type: BuyType
    @ObservedObject var model = PricesViewModel.shared
    private var isSelected: Bool { model.type == type}
    
    var body: some View {
        Button(action: { withAnimation { model.type = type } }) {
            PriceContent(type: type, isSelected: isSelected)
                .frame(width: 115, height: 145)
                .background(Color.gray.opacity(0.1))
        }
        .buttonStyle(.plain)
    }
}

/////////////////
///HELPERS
/////////////////

fileprivate struct PriceContent: View {
    let type: BuyType
    let isSelected: Bool
    @ObservedObject var model : ProductID.ViewModel
    
    init(type: BuyType, isSelected: Bool) {
        self.type = type
        self.isSelected = isSelected
        self.model = type.productID.viewModel
    }
    
    var body: some View {
        content
            .blur(radius: model.inProgress ? 3 : 0)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                
                if model.inProgress {
                    ProgressView()
                }
                
                if model.isPurchased {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 5)
                        .fill(.green)
                        .padding()
                }
            }
            .animation(.default, value: model.inProgress)
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            Text(type.monthsCount)
                .font(type == .forever ? .system(size: 40) : .system(size: 30))
            
            if type == .forever {
                VStack {
                    Text(type.periodName)
                        .font(.system(size: 14)).opacity(0.7)
                    
                    Text(model.price)
                        .font(.system(size: 18))
                }
                .offset(y:-2)
            } else {
                Text(type.periodName)
                    .font(.system(size: 14)).opacity(0.9)
                
                Text(model.price)
                    .font(.system(size: 18))
            }
        }
    }
}
```
