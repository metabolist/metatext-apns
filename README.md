# metatext-apns

This is a simple service to relay [WebPush](https://tools.ietf.org/html/rfc8030) notifications to Apple's push notification service. It was designed for Metatext, an iOS Mastodon client, but could theoretically be used for other purposes.

## Setup

### Environment

`metatext-apns` uses a [token-based connection](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns). You will need to set the following environment variables based on a key generated in the Apple developer portal:

* `APNS_KEY_ID`
* `APNS_AUTH_KEY`

You will also need to set these:

* `APPLE_TEAM_ID`
* `TOPIC`

Finally, you will need to specify the size of the connection pool:

* `CONNECTION_POOL_SIZE`

### Client

The service sets `{ "loc-key" : "apns-default-message" }` for the `alert` key of the `aps` payload dictionary. If decrypting the notification on the client fails, the value for `"apns-default-message"` in your `Localizable.strings` file is what will be displayed.

## Deployment

`metatext-apns` is a [Sinatra](http://sinatrarb.com) application, and can be deployed like any other [Rack](https://github.com/rack/rack)-based application. It is set up to be run using the [Puma](https://puma.io) web server.
