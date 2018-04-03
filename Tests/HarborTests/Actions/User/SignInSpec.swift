import Quick
import Nimble
import Foundation

@testable import Harbor

class SignInSpec: QuickSpec { override func spec() {
  var subject: User.SignIn!

  describe("#call") {
    it("signs in the user") {
      let session = Session(
        token: "test-token",
        expiresAt: Date()
      )

      subject = User.SignIn(
        auth: { _ in .init(value: session) }
      )

      let response = subject.call(
        email: "test@email.com",
        password: "test-password"
      )

      expect(response.value) === Current.user
    }
  }
}}