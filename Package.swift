// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyShop",
    platforms: [
      .iOS(.v13),
      .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyShop",
            targets: ["SwiftyShop"]
        ),
    ],
    dependencies: [
        .package(url: "https://gitlab.com/sergiy.vynnychenko/essentials.git", branch: "master"),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyShop",
            dependencies: [
                .product(name: "Essentials", package: "essentials"),
            ]
        ),
        .testTarget(
            name: "SwiftyShopTests",
            dependencies: [
                "SwiftyShop",
//                .product(name: "Essentials", package: "essentials"),
//                .product(name: "EssentialsTesting", package: "essentials"),
            ]
        ),
    ]
)


//Swift package target 'Essentials' is linked as a static library by 'SwiftyShopTests' and 'Essentials', but cannot be built dynamically because there is a package product with the same name.

