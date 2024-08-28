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
```
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
    
    var overlayText: String {
        switch self {
        case .forever:
            "Best Value"
        case .yearly:
            "7-Day Trial"
        case .monthly:
            "Monthly Plan"
        }
    }
}

```

2. Add app delegate to your app:

```
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

AppDelegate.swift:
``` 
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
```
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

(here is a lot of styling): 

```

import Foundation
import SwiftUI
import SwiftyShop

struct PriceBtn: View {
    let type: BuyType
    @ObservedObject var model = PricesViewModel.shared
    
    private var isSelected: Bool { model.type == type}
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: { withAnimation { model.type = type } }) {
            PriceContent(type: type, isSelected: isSelected)
                .frame(width: (390 - 48) / 3, height: 145)
                .background {
                    if isSelected {
                        Color(hex: 0x9281F7).opacity(0.1)
                    } else if isHovering {
                        Color(hex: 0x768BA6).opacity(0.22)
                    } else {
                        Color(hex: 0x768BA6).opacity(0.2)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(hex: 0x9281F7) : Color.clear, lineWidth: 4)
                )
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(isSelected ? Color(hex: 0x9281F7) : Color(hex: 0x768BA6).opacity(0.5))
                            .frame(height: 25)
                            .overlay(
                                Text(type.overlayText)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                                    .bold()
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onHover { hover in
                    isHovering = hover
                }
        }
        .buttonStyle(BuyButtonStyle())
        .padding(.top, 5)
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
                .bold()
                .padding(.top, type == .forever ? -41 : -30)
            
            if type == .forever {
                VStack {
                    Text(type.periodName)
                        .font(.system(size: 14)).opacity(0.7)
                    
                    Text(model.price)
                        .font(.system(size: 18))
                        .fontWeight(.semibold )
                        .foregroundColor(Color(hex: 0xF8F8F3))
                        .padding(.top, 1)
                }
                .offset(y:-2)
            } else {
                Text(type.periodName)
                    .font(.system(size: 14)).opacity(0.9)
                
                Text(model.price)
                    .font(.system(size: 18))
                    .fontWeight(.semibold )
                    .foregroundColor(Color(hex: 0xF8F8F3))
                    .padding(.top, 2)
            }
        }
        
    }
}

////////////////////
///STYLES
////////////////////

fileprivate struct BuyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.clear)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

```
