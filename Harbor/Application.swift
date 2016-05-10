
import AppKit

@objc(Application)
class Application: NSApplication {
  // MARK: Dependencies
  private let _component = AppComponent()
    .module(InteractorModule.self) { InteractorModule($0) }
    .module(ServiceModule.self) { ServiceModule($0) }
    .module(SystemModule.self) { SystemModule($0) }

  class func component() -> AppComponent {
    return (NSApp as! Application)._component
  }
}
