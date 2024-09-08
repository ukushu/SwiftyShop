import Foundation
import AppKit

func alert(msg: String, text: String) {
    DispatchQueue.main.sync {
        let alert: NSAlert = NSAlert()
        alert.messageText = msg
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
