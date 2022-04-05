import Foundation

public enum Stripe {
  public enum Api {
    public enum Currency: String {
      case USD
    }

    public struct PaymentIntent: Decodable {
      public var id: String
      public var clientSecret: String

      public init(id: String, clientSecret: String) {
        self.id = id
        self.clientSecret = clientSecret
      }
    }

    public struct Refund: Decodable {
      public var id: String

      public init(id: String) {
        self.id = id
      }
    }
  }
}
