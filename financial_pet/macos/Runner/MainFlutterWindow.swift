import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Размер современного смартфона (iPhone 15 Pro: 393×852 pt)
    let phoneSize = NSSize(width: 393, height: 852)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let x = screenFrame.midX - phoneSize.width / 2
    let y = screenFrame.midY - phoneSize.height / 2
    self.setFrame(NSRect(x: x, y: y, width: phoneSize.width, height: phoneSize.height), display: true)
    self.styleMask.remove(.resizable)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
