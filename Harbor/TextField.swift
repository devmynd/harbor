import AppKit

class TextField: NSTextField {
  private let commandKey = NSEventModifierFlags.CommandKeyMask.rawValue

  override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
    if let key = self.unmodifiedKeyForEvent(theEvent) {
      if let action = self.actionForKey(key) {
        if NSApp.sendAction(action, to:nil, from:self) {
          return true
        }
      }
    }

    return super.performKeyEquivalent(theEvent)
  }

  func unmodifiedKeyForEvent(event: NSEvent) -> String? {
    if event.type == .KeyDown {
      if (event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandKey {
        return event.charactersIgnoringModifiers
      }
    }

    return nil
  }

  func actionForKey(key: String) -> Selector? {
    switch(key) {
    case "x":
      return Selector("cut:")
    case "c":
      return Selector("copy:")
    case "v":
      return Selector("paste:")
    default:
      return nil
    }
  }
}