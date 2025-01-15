from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from Crypto.Util import Counter
from hashlib import sha256
import secrets
import base64
import sys
import os

# Function to encrypt using AES-256 in CBC mode with PKCS7 padding
def encrypt_aes_256_cbc_with_padding(ptx: str, key: str, iv: str = None):
    print()
    
    # Create the AES cipher in CBC mode
    cipher = AES.new(key, AES.MODE_CBC, iv=base64.b64decode(iv))

    # Apply PKCS7 padding, as AES CBC requires ptx is a multiple of the blocklength
    padded_ptx = pad(ptx.encode('utf-8'), AES.block_size) # Defaults to PKCS#7

    # Encrypt the text
    encrypted = cipher.encrypt(padded_ptx)

    # Return the encrypted text and the IV (Base64 encoded)
    return base64.b64encode(encrypted).decode('utf-8')

def main():
    gen_api_key = False

    app_pw = input("Enter the prefered APP Password: ")
    if len(app_pw) == 0:
        print("Password lenght can't be 0. You need to set a password")
        exit(1)
    elif len(app_pw) <= 8:
        print("WARNING: The entered password is weak")
    app_pw = sha256(app_pw.encode("utf-8")).digest()


    print("If you wish to get a random API-Key generated, just press 'enter' on the next input")
    api_key = input("Enter your API-Key: ")
    if len(api_key) == 0:
        api_key = "nl-" + secrets.token_urlsafe(2045)
        gen_api_key = True
    elif len(api_key) <= 32:
        print("WARNING: The entered API-Key is weak")
    
    print("If you wish to get a random IV generated, just press 'enter' on the next input")
    iv = input("Enter your IV(base64 encoded): ")
    try:
        if len(iv) == 0:
            iv = base64.b64encode(secrets.token_bytes(16)).decode("utf-8")
        elif len(base64.b64decode(iv)) < 16:
            raise
    except Exception:
        print("The IV needs to be a 16-Byte value, encoded as base64")

    ctx = encrypt_aes_256_cbc_with_padding(api_key, app_pw, iv)

    print("\n\n#### Provisioning Data ####\n")

    if gen_api_key:
        print(f"Generated API-Key: {api_key}")
    print(f"ENC_API_KEY: {ctx}")
    print(f"AES_IV: {iv}")

    if sys.argv[0][-4:] == ".exe":
        os.system("pause")

if __name__ == "__main__":
    main()
