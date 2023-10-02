import json
from cryptography.fernet import Fernet

fernet_key = Fernet.generate_key()
output = {
    "fernet_key": fernet_key.decode()
}
print(json.dumps(output))
