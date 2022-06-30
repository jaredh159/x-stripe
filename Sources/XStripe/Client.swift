import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public extension Stripe {
  struct Client {
    public var createPaymentIntent = createPaymentIntent(amountInCents:currency:metadata:secretKey:)
    public var cancelPaymentIntent = cancelPaymentIntent(id:secretKey:)
    public var createRefund = createRefund(paymentIntentId:secretKey:)
    public var getCheckoutSession = getCheckoutSession(id:secretKey:)
    public var createCheckoutSession = createCheckoutSession(data:secretKey:)
    public var getSubscription = getSubscription(id:secretKey:)
    public var createBillingPortalSession = createBillingPortalSession(customerId:secretKey:)

    public init() {}

    public init(
      createPaymentIntent: @escaping (
        Int,
        Stripe.Api.Currency,
        [String: String],
        String
      ) async throws -> Stripe.Api.PaymentIntent,
      cancelPaymentIntent: @escaping (String, String) async throws -> Stripe.Api.PaymentIntent,
      createRefund: @escaping (String, String) async throws -> Stripe.Api.Refund,
      getCheckoutSession: @escaping (String, String) async throws -> Stripe.Api.CheckoutSession,
      createCheckoutSession: @escaping (
        CheckoutSessionData,
        String
      ) async throws -> Stripe.Api.CheckoutSession,
      getSubscription: @escaping (String, String) async throws -> Stripe.Api.Subscription,
      createBillingPortalSession: @escaping (String, String) async throws -> Stripe.Api
        .BillingPortalSession
    ) {
      self.createPaymentIntent = createPaymentIntent
      self.cancelPaymentIntent = cancelPaymentIntent
      self.createRefund = createRefund
      self.getCheckoutSession = getCheckoutSession
      self.createCheckoutSession = createCheckoutSession
      self.getSubscription = getSubscription
      self.createBillingPortalSession = createBillingPortalSession
    }
  }
}

// implementations

private func createBillingPortalSession(
  customerId: String,
  secretKey: String
) async throws -> Stripe.Api.BillingPortalSession {
  let (data, res) = try await HTTP.postFormUrlencoded(
    ["customer": customerId],
    to: "https://api.stripe.com/v1/billing_portal/sessions",
    auth: .basic(secretKey, "")
  )
  return try await decode(Stripe.Api.BillingPortalSession.self, data: data, response: res)
}

private func getSubscription(
  id: String,
  secretKey: String
) async throws -> Stripe.Api.Subscription {
  let (data, response) = try await HTTP.get(
    "https://api.stripe.com/v1/subscriptions/\(id)",
    auth: .basic(secretKey, "")
  )
  return try await decode(Stripe.Api.Subscription.self, data: data, response: response)
}

private func getCheckoutSession(
  id: String,
  secretKey: String
) async throws -> Stripe.Api.CheckoutSession {
  let (data, response) = try await HTTP.get(
    "https://api.stripe.com/v1/checkout/sessions/\(id)",
    auth: .basic(secretKey, "")
  )
  return try await decode(Stripe.Api.CheckoutSession.self, data: data, response: response)
}

private func createCheckoutSession(
  data: Stripe.CheckoutSessionData,
  secretKey: String
) async throws -> Stripe.Api.CheckoutSession {
  var params = [
    "success_url": data.successUrl,
    "cancel_url": data.cancelUrl,
    "mode": data.mode.rawValue,
  ]

  for (index, lineItem) in data.lineItems.enumerated() {
    params["line_items[\(index)][quantity]"] = String(lineItem.quantity)
    params["line_items[\(index)][price]"] = lineItem.priceId
  }

  if let customerEmail = data.customerEmail {
    params["customer_email"] = customerEmail.replacingOccurrences(of: "+", with: "%2b")
  }

  if let trialPeriodDays = data.trialPeriodDays {
    params["subscription_data[trial_period_days]"] = String(trialPeriodDays)
  }

  if let clientReferenceId = data.clientReferenceId {
    params["client_reference_id"] = clientReferenceId
  }

  let (data, response) = try await HTTP.postFormUrlencoded(
    params,
    to: "https://api.stripe.com/v1/checkout/sessions",
    auth: .basic(secretKey, "")
  )

  return try await decode(Stripe.Api.CheckoutSession.self, data: data, response: response)
}

private func createRefund(
  paymentIntentId: String,
  secretKey: String
) async throws -> Stripe.Api.Refund {
  let (data, response) = try await HTTP.postFormUrlencoded(
    ["payment_intent": paymentIntentId],
    to: "https://api.stripe.com/v1/refunds",
    auth: .basic(secretKey, "")
  )
  return try await decode(Stripe.Api.Refund.self, data: data, response: response)
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

  let (data, response) = try await HTTP.postFormUrlencoded(
    formData,
    to: "https://api.stripe.com/v1/payment_intents",
    auth: .basic(secretKey, "")
  )

  return try await decode(Stripe.Api.PaymentIntent.self, data: data, response: response)
}

private func cancelPaymentIntent(
  id: String,
  secretKey: String
) async throws -> Stripe.Api.PaymentIntent {
  let (data, response) = try await HTTP.post(
    "https://api.stripe.com/v1/payment_intents/\(id)/cancel",
    auth: .basic(secretKey, "")
  )
  return try await decode(Stripe.Api.PaymentIntent.self, data: data, response: response)
}

private struct WrappedError: Decodable {
  let error: Stripe.Api.Error
}

private func decode<T: Decodable>(
  _: T.Type,
  data: Data,
  response: HTTPURLResponse
) async throws -> T {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  if response.statusCode >= 300 {
    if let stripeError = try? decoder.decode(WrappedError.self, from: data) {
      throw stripeError.error
    } else {
      throw Stripe.Api.Error(
        type: "unknown_error",
        message: String(data: data, encoding: .utf8) ?? nil
      )
    }
  }
  do {
    return try decoder.decode(T.self, from: data)
  } catch {
    throw HttpError.decodingError(error, String(data: data, encoding: .utf8) ?? "")
  }
}

// extensions

public extension Stripe.Client {
  static let live = Stripe.Client(
    createPaymentIntent: createPaymentIntent(amountInCents:currency:metadata:secretKey:),
    cancelPaymentIntent: cancelPaymentIntent(id:secretKey:),
    createRefund: createRefund(paymentIntentId:secretKey:),
    getCheckoutSession: getCheckoutSession(id:secretKey:),
    createCheckoutSession: createCheckoutSession(data:secretKey:),
    getSubscription: getSubscription(id:secretKey:),
    createBillingPortalSession: createBillingPortalSession(customerId:secretKey:)
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
    },
    getCheckoutSession: { _, _ in
      .init(id: "cs_123", url: nil, subscription: "sub_123", clientReferenceId: nil)
    },
    createCheckoutSession: { _, _ in
      .init(id: "cs_123", url: "/checkout.session/url", subscription: nil, clientReferenceId: nil)
    },
    getSubscription: { _, _ in
      .init(id: "sub_123", status: .trialing, customer: "cus_123")
    },
    createBillingPortalSession: { _, _ in
      .init(id: "bps_123", url: "/billing_portal.session/url")
    }
  )
}
