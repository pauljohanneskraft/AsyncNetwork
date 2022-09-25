<img src="https://user-images.githubusercontent.com/15239005/178734626-93f21b81-3072-498f-be01-13d4e459f587.png" width=50%>
Lightweight async/await networking library with interceptor support.

## 🚀 Getting started

`AsyncNetwork`'s session acts as a wrapper to [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) by adding support for interceptors. Interceptors can be used to easily extract common functionality for the preparation of [`URLRequests`](https://developer.apple.com/documentation/foundation/urlrequest) and the handling or retrying of the respective responses. This library allows you to write custom interceptors, but also comes with a couple of handy interceptors for authentication, status code validation, adding custom headers, logging and more!

Let's see how we can make use of that.

```swift
let session = Session(
    session: .shared,
    interceptors: [
        .setHeaders { headers in
            headers["Accept-Language"] = Locale.current.languageCode
            headers["Accept-Type"] = "application/json"
            headers["Content-Type"] = "application/json"
        },
        .validateStatus(),
        .dataResponseLogger(),
    ],
    maximumRetryCount: 1,
)
```

In the code example above, a `Session` is created on the basis of an underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) and an array of interceptors. Interceptors can be thought of as layers, as they are called in order during request preparation and in reverse order for handling the response.

The first interceptor sets a set of headers, so that each request contains the correct "Accept-Language", "Accept-Type" and "Content-Type" header fields. In this example, we are overriding existing headers, which we might not always want to do, so you might want to have a look at `.addHeaders` instead.

The second interceptor validates that the status code of the response is between 200 and 299. If not, it throws an error and makes the whole request fail based on that. Successive interceptors (in this case, the one above it, which is not doing anything for response handling anyways), will not be called due to the error being thrown.

The third and last interceptor logs the response of every request response to the console. You can modify `subsystem`, `category` and `logType` as well here, if you want to customize that output. For even more control, you might want to look into the more general `.logger` interceptor as well.

## 🔩 Installation

AsyncNetwork is currently only available via Swift Package Manager. See [this tutorial by Apple](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) on how to add a package dependency to your Xcode project.

## ✍️ Author

Paul Kraft

## 📄 License

AsyncNetwork is available under the MIT license. See the LICENSE file for more info.
