import Foundation
import AppKit

public func alertMacOs(msg: String, text: String) {
    DispatchQueue.main.async {
        let alert: NSAlert = NSAlert()
        alert.messageText = msg
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
