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
        
        // Important: Don't automatically commit on end editing
        textField.cell?.sendsActionOnEndEditing = false
        
        // Set initial text value
        textField.stringValue = text
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only update the text if it differs from what's already in the field
        // This prevents cursor position resetting while typing
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        // CRITICAL: Update the bound value as the user types
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            DispatchQueue.main.async {
                self.parent.text = textField.stringValue
            }
        }
        
        // Handle the completion of editing
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            // Update the final text value
            self.parent.text = textField.stringValue
            
            // Check if editing ended due to pressing Enter or Tab (field being unfocused)
            if let fieldEditor = textField.currentEditor(),
               let event = NSApp.currentEvent,
               event.type == .keyDown, 
               event.keyCode == 36 { // 36 is Enter key
                // Call the onCommit callback if provided
                self.parent.onCommit?()
            }
        }
        
        // Custom key handling
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle escape key press
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                // We want field's text to be saved but not committed
                control.window?.makeFirstResponder(nil)
                return true
            }
            
            // Let other keys be handled normally
            return false
        }
    }
}