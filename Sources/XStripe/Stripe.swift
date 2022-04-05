import Foundation

public enum Stripe {
  public enum Api {
    public enum Currency: String {
      case USD
    }

    public struct PaymentIntent: Decodable {
      public var id: String
      public var clientSecret: String
    }

    public struct Refund: Decodable {
      public var id: String
    }
  }
}
