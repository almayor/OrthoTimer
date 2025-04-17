import SwiftUI
import AppKit

// Custom NSTextField wrapper for better control over appearance and behavior
struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: (() -> Void)? = nil
    var font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.font = font
        textField.focusRingType = .default
        textField.bezelStyle = .roundedBezel
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.cell?.usesSingleLineMode = true
        textField.maximumNumberOfLines = 1
        textField.cell?.sendsActionOnEndEditing = true
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
                parent.onCommit?()
            }
        }
    }
}