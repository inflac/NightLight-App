import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart'; // For SHA256
import 'package:convert/convert.dart'; // For hex encoding
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(NightLight());
}

class NightLight extends StatelessWidget {
  const NightLight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PasswordProtectedApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PasswordProtectedApp extends StatefulWidget {
  const PasswordProtectedApp({super.key});

  @override
  PasswordProtectedAppState createState() => PasswordProtectedAppState();
}

class PasswordProtectedAppState extends State<PasswordProtectedApp> {
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isUnlocked = false;
  String _decryptedApiKey = "";
  String _currentStatus = "";
  bool _isProcessingRequest = false;

  // Get the API_URL from .env file
  final String _apiUrl = dotenv.get('API_URL');

  // Get the encrypted API-Key (AES-256, Base64-encoded)
  final String _encryptedApiKey = dotenv.get("ENC_API_KEY");

  @override
  void initState() {
    super.initState();
    _fetchCurrentStatus();
    checkStoredApiKey();
  }

  // Try to read the decrypted API-Key from secure storage
  Future<void> checkStoredApiKey() async {
    String? apiKey = await _secureStorage.read(key: 'api_key', aOptions: _getAndroidOptions());

    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _isUnlocked = true;
        _decryptedApiKey = apiKey;
      });
    }
  }

  Future<void> storeNewApiKey(String key) async {
      await _secureStorage.write(key: 'api_key', value: key, aOptions: _getAndroidOptions());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isUnlocked ? _buildMainPage() : _buildPasswordScreen(),
    );
  }

  // Helper for constant time comparison of two byte arrays
  bool _constantTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  // Encrypt or decrypt a plaintext with a given password
  String _encdecApiKey(String ptx, String password, bool encNotDec) {
    try {
      // Generate a SHA-256 hash from the password for key derivation
      final pwHash = sha256.convert(utf8.encode(password)).bytes;
      final key = encrypt.Key.fromBase16(hex.encode(pwHash));

      // Retrieve IV from environment variable (16 bytes for AES-CBC)
      final iv = encrypt.IV(base64Decode(dotenv.get("AES_IV")));

      // Initialize encrypter with AES in CBC mode
      final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7")
      );

      if (encNotDec) {
        // Encrypt provided plaintext
        final encrypted = encrypter.encrypt(ptx, iv: iv);
        return encrypted.base64;
      } else {
        // Decrypt provided base64 ciphertext
        return encrypter.decrypt64(ptx, iv: iv);
      }
    } catch (e) {
      return ""; // Return an empty string in case of an error
    }
  }

  // Check if the decrypted API-Key is correct, by encrypting the decrypted API-Key
  // again and comparing it with the stored API-Key
  void _validatePassword(String inputPassword) {
    final decryptedApiKey = _encdecApiKey(_encryptedApiKey, inputPassword, false);

    if (decryptedApiKey.isNotEmpty) {
      final encDecryptedApiKey = _encdecApiKey(decryptedApiKey, inputPassword, true);

      if (encDecryptedApiKey.isNotEmpty) {
        if (_constantTimeEqual(utf8.encode(encDecryptedApiKey), utf8.encode(_encryptedApiKey))){
          setState(() {
            _isUnlocked = true;
            _decryptedApiKey = decryptedApiKey;
          });
          storeNewApiKey(_decryptedApiKey);
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Falsches Passwort", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red, // Set the background color to red
      ),
    );
  }

  void _fetchCurrentStatus() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
      );
      if (response.statusCode == 200) {
        setState(() {
          _currentStatus = json.decode(response.body)['status'] ?? "Unbekannter Status";
        });
      } else {
        _currentStatus = "API returned: $response.statusCode";
      }
    } catch (e) {
      _currentStatus = "Connection error";
    }
  }

  void _displayFrame({required Color color}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: color, // Use the passed color parameter
              width: 6,
            ),
            borderRadius: BorderRadius.circular(60),
          ),
        ),
      ),
    );

    // Insert the overlay entry to show the frame
    overlay.insert(overlayEntry);

    // Remove the frame after a delay (e.g., 3 seconds)
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Widget _buildPasswordScreen() {
    final TextEditingController passwordController = TextEditingController();

    return Container(
      color: Colors.black, // Set the background color to black
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // Add padding to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add a logo above the password field
              Image.asset(
                'assets/logo.png', // Path to your logo image
                height: 100, // Adjust the size as needed
                fit: BoxFit.contain,
              ),
              SizedBox(height: 34),
              // Add some spacing between the logo and the input field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Passwort",
                  labelStyle: TextStyle(color: Colors.white),
                  // Label text color
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.blue), // Focused border color
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white), // Text color
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _validatePassword(passwordController.text);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  // Größere Buttons
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Entsperren"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white54),
              ),
              child: Text(
                "Aktueller Status: $_currentStatus",
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            _buildStatusButton(
              label: "Dienst Entfällt",
              newCurrentStatus: "canceled",
              url: "$_apiUrl/update_status?status=canceled&story=true",
              color: Colors.redAccent,
            ),
            SizedBox(height: 12),
            _buildStatusButton(
              label: "Dienst Deutsch",
              newCurrentStatus: "german",
              url: "$_apiUrl/update_status?status=german&story=true",
              color: Colors.amber,
            ),
            SizedBox(height: 12),
            _buildStatusButton(
              label: "Dienst English & Deutsch",
              newCurrentStatus: "english",
              url: "$_apiUrl/update_status?status=english&story=true",
              color: Colors.blueAccent,
            ),
            SizedBox(height: 12),
            _buildStatusButton(
              label: "Zurücksetzen",
              newCurrentStatus: "default",
              url: "$_apiUrl/update_status?status=default",
              color: Colors.grey,
            ),
            if (_isProcessingRequest) ...[
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                "Anfrage wird bearbeitet...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required newCurrentStatus,
    required String url,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () => _openUrl(url, newCurrentStatus),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: 18)),
    );
  }

  void _openUrl(String url, String newCurrentStatus) async {
    setState(() {
      _isProcessingRequest = true;
    });

    try {
      String urlWithApiKey = "$url&api_key=$_decryptedApiKey";
      final response = await http.get(Uri.parse(urlWithApiKey));

      setState(() {
        _isProcessingRequest = false;
        if (response.statusCode == 200) {
          _currentStatus = newCurrentStatus;
          _displayFrame(color: Colors.green);
        } else {
          _currentStatus = "Fehler: ${response.statusCode} - ${response.body}";
          _displayFrame(color: Colors.red);
        }
      });
    } catch (e) {
      setState(() {
        _isProcessingRequest = false;
        _currentStatus = "Netzwerkfehler oder ungültige Anfrage.";
        _displayFrame(color: Colors.red);
      });
    }
  }
}