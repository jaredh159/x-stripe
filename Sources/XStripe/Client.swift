import XHttp

public extension Stripe {
  struct Client {
    public var createPaymentIntent = createPaymentIntent(amountInCents:currency:metadata:secretKey:)
    public var cancelPaymentIntent = cancelPaymentIntent(id:secretKey:)
    public var createRefund = createRefund(paymentIntentId:secretKey:)
  }
}

// implementation

private func createRefund(
  paymentIntentId: String,
  secretKey: String
) async throws -> Stripe.Api.Refund {
  try await HTTP.postFormUrlencoded(
    ["payment_intent": paymentIntentId],
    to: "https://api.stripe.com/v1/refunds",
    decoding: Stripe.Api.Refund.self,
    auth: .basic(secretKey, ""),
    keyDecodingStrategy: .convertFromSnakeCase
  )
}

private func createPaymentIntent(
  amountInCents: Int,
  currency: Stripe.Api.Currency,
  metadata: [String: String],
  secretKey: String
) async throws -> Stripe.Api.PaymentIntent {
  var formData = [
    "amount": "\(amountInCents)",
    "currency": "\(currency.rawValue)",
  ]

  for (key, value) in metadata {
    formData["metadata[\(key)]"] = value
  }

  return try await HTTP.postFormUrlencoded(
    formData,
    to: "https://api.stripe.com/v1/payment_intents",
    decoding: Stripe.Api.PaymentIntent.self,
    auth: .basic(secretKey, ""),
    keyDecodingStrategy: .convertFromSnakeCase
  )
}

private func cancelPaymentIntent(
  id: String,
  secretKey: String
) async throws -> Stripe.Api.PaymentIntent {
  try await HTTP.post(
    "https://api.stripe.com/v1/payment_intents/\(id)/cancel",
    decoding: Stripe.Api.PaymentIntent.self,
    auth: .basic(secretKey, ""),
    keyDecodingStrategy: .convertFromSnakeCase
  )
}

// extensions

public extension Stripe.Client {
  static let live = Stripe.Client(
    createPaymentIntent: createPaymentIntent(amountInCents:currency:metadata:secretKey:),
    cancelPaymentIntent: cancelPaymentIntent(id:secretKey:),
    createRefund: createRefund(paymentIntentId:secretKey:)
  )

  static let mock = Stripe.Client(
    createPaymentIntent: { _, _, _, _ in
      .init(id: "pi_mock_id", clientSecret: "pi_mock_secret")
    },
    cancelPaymentIntent: { _, _ in
      .init(id: "pi_mock_id", clientSecret: "pi_mock_secret")
    },
    createRefund: { _, _ in
      .init(id: "re_mock_id")
    }
  )
}
