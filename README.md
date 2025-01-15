# NightLight App

The NightLight app is designed to interact with the [Nightlight API](https://github.com/inflac/NightLight),
which allows updating the status of a [Nightline](https://nightlines.eu/) through simple GET requests.

## Provisioning & Build
In order to get the API-Key, it's ciphertext and IV in the correct format, there is a
provisioning script, available as a python script, bash script or .exe.
The provisioning program will ask you to enter the following values:
* Preferred password (Needed on first app startup)
* API-Key (Script can also generate one for you)
* IV for AES (Script can also generate one for you)

Once you entered the values, the script will generate everything you need to enter into the .env file.
An example of the .env file, named `.env.example` can be found in the base directory. Rename this
file to `.env` and enter the values the provisioning script gave you. Also enter the APIs URL.
This might be something like `https://status.example.com`. Make sure not to have a trailing / in the URL.
Also, ensure your API is reachable over HTTPS. If you allow access over HTTP, this will expose the API-Key.
For more information about security, read the [security section](https://github.com/inflac/NightLight#security-notes) of
the API and the [security section](#security) below.

For the app icon and image, displayed on the password screen, place an image named `logo.png` in
the assets folder. Ensure the images quality is good enough (E.g. >400px x >400px).

Now that your app is provisioned, you are ready to build it. Therefor, run the following commands:
1. `flutter clean`
2. `flutter pub get`
3. `dart run flutter_launcher_icons`
4. `flutter build apk --release`
You will find the apk in `build/app/outputs/flutter-apk/app-release.apk`

## Design

## Security
The app protects the API key by storing it encrypted within the source code, using AES-256 CBC with PKCS#7 padding.
On first app start, the user is required to enter a password in order to decrypt the API-Key.
The decrypted key is then stored using androids 'secure-storage'. The next time the app gets opened,
the API-Key is read from the secure-storage without the user being asked for the password again.

Even though there should be no possibility for a third party to get either access to the app nor the API-Key,
ensure to handle the distribution of the APK with care. Most importantly, choose a strong password. Otherwise
every security mechanism implemented is useless.

Now that you are informed about the security of the app, make sure to also read the [security section](https://github.com/inflac/NightLight#security-notes) of the API.

