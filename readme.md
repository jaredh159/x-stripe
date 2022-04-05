# XStripe

A very bare-bones **Swift Stripe Client/SDK**, written with async/await.

## Anti-pitch

This library was written to cover _only_ and _exactly_ a single use-case for one of my
vapor apps. It's open source, and you're welcome to use it, but it has some major
limitations currently -- including that it only supports 3 api operations (creating a
payment intent, canceling a payment intent, and creating a refund), and only supports
`USD` currency. That said, if it looks promising, and you'd like to see it broadened, open
an issue, or open a PR, I'm open to making it more general-purpose.

## Usage

_Create_ a **payment intent**:

```swift
import XStripe

let amountInCents = 499;
let additionalMetadata = ["orderId": "internal-123-abc"]
let stripeSecretKey = "sk_sosecret-123"

let paymentIntent = try await Stripe.Client().createPaymentIntent(
  amountInCents,
  .USD,
  additionalMetadata,
  stripSecretKey
)
```

_Cancel_ a **payment intent**:

```swift
// [...]
let paymentIntent = try await Stripe.Client().cancelPaymentIntent("pi_123", secretKey)
```

_Create_ a **refund**:

```swift
// [...]
let refund = try await Stripe.Client().createRefund("pi_123", secretKey)
```

## Environment/Mocking/Testing

This library was designed to be used with the
[dependency injection approach from pointfree.co](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy):

```swift
import XStripe

struct Environment {
  var stripeClient: Stripe.Client
  // other dependencies...
}

extension Environment {
  static let live = Environment(stripeClient: Stripe.Client.live)
  static let mock = Environment(stripeClient: Stripe.Client.mock)
}

var Current = Environment.live

// 🎉 you can swap out your own mock implementation:
Current.stripeClient.createRefund = { _, _ in fatalError("should not be called") }
```

## Installation

Use SPM:

```diff
// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "RadProject",
  products: [
    .library(name: "RadProject", targets: ["RadProject"]),
  ],
  dependencies: [
+   .package(url: "https://github.com/jaredh159/x-stripe.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "RadProject", dependencies: [
+     .product(name: "XStripe", package: "x-stripe"),
    ]),
  ]
)
```
