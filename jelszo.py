import hashlib
import getpass

def hash_password(password):
    password_bytes = password.encode('utf-8')
    hash_object = hashlib.sha256(password_bytes)
    return hash_object.hexdigest()

password = getpass.getpass("Jelszó: ")

hashed_password = hash_password(password)
print(hashed_password)

with open('/tmp/.python.pwd', 'w') as file:
    file.write(password)
