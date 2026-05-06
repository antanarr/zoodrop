import Foundation

// By placing these in their own file, these custom notification names
// are available globally across the entire application, ensuring any
// component can safely publish or subscribe to them.
extension Notification.Name {
    static let grantMiniReward = Notification.Name("GrantMiniReward")
    static let showZooClubPromo = Notification.Name("ShowZooClubPromo")
}
