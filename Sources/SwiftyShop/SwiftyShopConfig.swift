
import Foundation

public class SwiftyShopConfig {
    public static var shared: SwiftyShopConfig!
    
    public init(products: [String], dictFilePath: String, dictFilePass: String) {
        self.products = products
        self.dictFilePath = dictFilePath
        self.dictFilePass = dictFilePass
    }
    
    public private(set) var products: [String]
    
    /// location of cache file with details of users shop transactions
    public private(set) var dictFilePath: String
    
    /// password for file
    public private(set) var dictFilePass: String
}
