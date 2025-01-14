# NightLight

The NightLight app is designed to interact with the [Nightlight API](https://github.com/inflac/NightLight),
which allows updating the status of a NightLine through simple GET requests.

## Provisioning & Build
In order to get the API-Key, it's ciphertext, the IV etc. in the correct format, I created a
provisioning script. Available as python script, bash script or .exe. The provisioning program
will ask you to enter the following values:
* Preferred password (Needed on first APP startup)
* API-Key (Script can also generate on for you)
* IV for AES (Script can also generate on for you)

Once you entered the values, the script will generate everything you need to enter into the .env file.
An example of the .env file, named `.env.example` can be found in the base directory. Rename this
file to `.env` and enter the values the provisioning script gave you. Also enter the APIs URL.
This might be something like `https://status.example.com`. Make sure not to have a trailing / in the URL.
Also, ensure your API is reachable over HTTPS. If you allow access over HTTP, this will expose the API-Key.
For more information about security, read the [security section](https://github.com/inflac/NightLight#security-notes) of
the API and the [security section](#security) below.

Now that your app is provisioned, you are ready to build it. Therefor, run the following commands:
1. `flutter clean`
2. `flutter pub get`
3. `flutter build apk --release`
You will find the apk in `build/app/outputs/flutter-apk/app-release.apk`

## Design

## Security
The app protects the API key by storing it encrypted within the source code, using AES-256 CTR with #PKCs7.
On first app start, the user is required to enter a password in order to decrypt the API-Key.
The decrypted key is then stored using androids 'secure-storage'. The next time the app gets opened,
the API-Key is read from the secure-storage without the user being asked for the password again.

Even though there should be no possibility for a third party to get either access to the App nor the API-Key,
ensure to handle the distribution of the APK with care. Most importantly, choose a strong password. Otherwise
every security mechanism implemented is useless.

Now that you are informed about the security of the app, make sure to also read the [security section](https://github.com/inflac/NightLight#security-notes) of the API.

