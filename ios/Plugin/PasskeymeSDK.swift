import Foundation
import UIKit
import Capacitor

@objc public class PasskeymeSDK: NSObject {
    
    private let accountManager = AccountManager()
    
    func passkeyRegister(_ challenge: RegisterChallenge, _ anchor: UIWindow, _ call: CAPPluginCall) {
        self.accountManager.signUpWith(challenge, anchor, call)
    }

    func passkeyAuthenticate(_ challenge: AuthChallenge, _ anchor: UIWindow, _ call: CAPPluginCall) {
        self.accountManager.signInWith(challenge, anchor, true, call)
    }
}
