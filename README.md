# SimpleSMTPClient

An _experimental_ SMTP client, written in Swift and based on SwiftNIO 2.

# Supported platforms

Works on macOS, iOS and Linux. In theory.

# State and compatibility

* ⚠️ Untested against most SMTP server software.
* ⚠️ Untested against most email clients.
* Seems to work for some very specific use-cases.
* Don't use it in production; you will likely regret it!

# Usage

### Specify the dependendy


In Package.swift:

```swift
// in your package:
dependencies: [
    .package(url: "https://github.com/andreasley/SimpleSMTPClient.git", branch: "master")
]

// in your target:
dependencies: [
    .product(name: "SimpleSMTPClient", package: "SimpleSMTPClient")
]),

```
In Xcode:
[Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)


### Import the module

```swift
import SimpleSMTPClient
```

### Configure the server

```swift
let server = SMTPServerConfiguration(
    hostname: "someSmtpServerHost.com",
    port: .defaultForTLS,
    security: .TLS,
    authentication: .login(username: "someUsername", password: "somePassword")
)
```

### Create the message

```swift
let email = Email()
email.subject = "Hello there!"
email.from = "some.person@sendinghost.com"
email.to = ["some.person@receivinghost.com"]
email.htmlBody = "<html><body><h1>Email attachment test</h1></body></html>"
```

### Add an attachment

```swift
let textAttachment = try Attachment(filename: "test.txt", data: "hello".data(using: .utf8)!, contentType: "text/plain")
email.attachments.append(textAttachment)
```

### Send the email

```swift
let mailer = Mailer(server: server)
try mailer.send(email: email) { result in
    switch result {
    case .success(_):
        print("✅")
    case .failure(let error):
        print("❌ : \(error)")
    }
}
```

# Contributing

Feel free to fork (see [license](License.md)) or contribute.

# Attribution

Partially based on [https://github.com/apple/swift-nio-examples/tree/master/NIOSMTP](https://github.com/apple/swift-nio-examples/tree/master/NIOSMTP)
