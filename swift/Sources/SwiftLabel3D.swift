import SwiftGodot

@Godot
class SwiftLabel3D: Label3D, @unchecked Sendable {
  override func _ready() {
    text = "Hello from Swift"
  }
}
