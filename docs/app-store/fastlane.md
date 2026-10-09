# fastlane

Lanes (run from the repo root):

```bash
fastlane beta      # xcodegen → Release archive → TestFlight (build number = latest + 1)
fastlane metadata  # upload App Store texts from fastlane/metadata
```

## Authentication
An App Store Connect API key (Users and Access → Integrations → App Store Connect API, role App Manager).
Put the `.p8` file in `fastlane/` and create `fastlane/AuthKey.json` — both are git-ignored:

```json
{ "key_id": "XXXXXXXXXX", "issuer_id": "xxxxxxxx-…", "key_filepath": "fastlane/AuthKey_XXXXXXXXXX.p8", "in_house": false }
```

The key is per team, so the Subloom key works here too.

## Before the first `beta`
- Create the app in App Store Connect with bundle ID `com.ibrahimfatihtaner.tixday` and name "Tixday – Countdown Widgets".
- Register the App Group `group.com.ibrahimfatihtaner.tixday` (Xcode's automatic signing does this with `-allowProvisioningUpdates`).
- Put the RevenueCat `appl_` key in `AppConfig` (Release).

## Metadata
`fastlane/metadata/<locale>/` holds name, subtitle, keywords and description (en-US and tr so far).
Support and privacy URLs still need a published site before review.
