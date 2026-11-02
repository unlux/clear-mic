# Privacy policy

Effective 2 November 2026. Applies to the unmodified Clear Mic 0.1.3 release.
Maintainer: Lakshay Choudhary, GitHub [unlux](https://github.com/unlux).
Contact: [lakshaychoudhary77712@gmail.com](mailto:lakshaychoudhary77712@gmail.com).

## Audio and microphone access

Clear Mic processes microphone samples on your Mac using Desert Ant Labs Clear.
During normal use, the app holds audio in memory, processes it locally, and sends
it to the virtual audio output you select. Clear Mic does not save recordings,
upload microphone audio or cleaned audio, or run a transcription service.

You choose when to start. macOS controls microphone permission. Stop releases the
microphone; closing the controls window keeps an active session running in the
menu bar. Quit ends the app. Other apps that access the virtual microphone can
record or transmit its audio under their own permissions and privacy policies.
Clear Mic cannot control what Meet, Zoom, Discord, or other receiving apps do.

The separate benchmark tool writes audio files to the output directory you give
it. This does not happen in normal Clear Mic use. The optional live diagnostic
uses the microphone briefly and saves no audio.

## Downloads and required SDK licensing traffic

Local audio processing does not mean the app makes no network requests.
After you choose Start, model preparation can make requests before macOS asks
for microphone permission, even if you later deny permission or never speak.
The model check and live diagnostic can also prepare the model.

- Model downloads go to Hugging Face and its download/CDN providers. Requests
  identify the Clear repository, model revision and files being downloaded.
  The pinned SDK selects Clear revision `v0.3.0` and the studio variant.
- Desert Ant's SDK requests and activates a usage license through
  `https://events.desertant.com/api/v1/license` and `/activate`. It sends a random,
  persistent installation UUID; the app identifier `dev.unlux.clearmic`; model
  name and version; SDK name and version; and a platform label. SDK 4.1.0 labels
  macOS as `server`. Activation sends the signed license token returned by the
  service. These requests do not contain audio, model outputs, microphone/output
  device UIDs, or a user account supplied by Clear Mic.
- Receiving services also see network information such as your IP address,
  request timing and ordinary HTTP headers. We do not describe these requests as
  anonymous or promise that a network operator cannot identify a connection.

Desert Ant describes this licensing signal as monthly active-device counting,
not advertising tracking. The SDK has no supported telemetry opt-out, and its
license prohibits tampering with reporting. Stop and bypass do not cancel SDK
background licensing requests or scheduled retries. Quit ends this app process.
Cached models can process offline, but the SDK may still attempt licensing
requests. A missing or corrupt model cache requires a successful download.

Clear Mic sets no API keys or download tokens. Custom builds or launch
environments can supply SDK endpoint, app-identity or authentication overrides;
those configurations can change the recipient or request headers described here.
This policy describes the default release configuration.

## Local storage and retention

The app stores the selected microphone and virtual-output UIDs in macOS app
preferences. The SDK stores its installation UUID, cached license token and
activation/retry state there too, under the `dev.unlux.clearmic` preferences
domain. These are ordinary preferences, not a Keychain vault. A token's expiry
does not mean its stored record is immediately erased.

Downloaded models and manifests are normally cached beneath
`~/Library/Caches/desert-ant-models/desert-ant-labs/clear/`. The SDK has no fixed
age-based deletion schedule for those files or preferences. macOS may evict
caches, and Core ML can maintain additional system-managed caches. Removing the
.app alone does not necessarily remove preferences or downloaded models.

macOS may retain system diagnostic logs independently. If you send a bug report,
review it first and omit private audio, license tokens, installation identifiers
and other sensitive information. Do not paste private information into public
GitHub issues.

## Maintainer, third parties and your choices

The maintainer operates no audio-upload server or separate Clear Mic analytics
service for this release. Information you voluntarily send by email or GitHub
is used to handle your request and maintain the project. Public GitHub activity
is public. GitHub, email providers and other services process it under their own
policies and retention rules. No fixed retention period is promised for support
correspondence or public project history.

Desert Ant states that it is the controller of its licensing telemetry. Its
server retention periods, hosting locations and deletion procedures are not
specified in the audited SDK or license. Clear Mic cannot erase records held by
Desert Ant, Hugging Face, their providers, or your call applications. Contact the
relevant provider for requests concerning its records.

You can stop or quit Clear Mic and revoke its microphone access in macOS System
Settings. For local data removal, quit first and remove this app's preferences
through macOS's `defaults` tools if desired. Review model cache contents before
removing them because other Desert Ant applications may share those files.
There is no in-app account, advertising profile or audio recording history to
close or delete.

Depending on applicable law, you may have rights to request access, correction,
deletion or other action concerning personal information a recipient holds.
Contact the maintainer about information you sent to this project. Contact the
independent recipient about information it holds. This policy does not limit
rights that applicable law gives you.

## Sources and changes

- [Desert Ant license, section 7](https://license.desertant.com/1.0)
- [Audited SDK licensing implementation](https://github.com/Desert-Ant-Labs/desert-ant-core/blob/86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb/Sources/Usage/Licensing.swift)
- [Hugging Face privacy policy](https://huggingface.co/privacy)
- [GitHub privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)

Material changes will be documented with an updated policy date and release.
The app has no automatic updater; inspect the policy for the version you use.
