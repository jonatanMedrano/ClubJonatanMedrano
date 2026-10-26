"""Obtiene un ID token de Firebase para probar la API en Swagger (/docs).
Uso:  python obtener_token.py correo@ejemplo.com tuPassword
Necesita FIREBASE_WEB_API_KEY en el .env"""
import json
import os
import sys
import urllib.error
import urllib.request

from dotenv import load_dotenv

load_dotenv()
key = os.getenv("FIREBASE_WEB_API_KEY")
if not key or len(sys.argv) != 3:
    sys.exit("Uso: python obtener_token.py correo password  (y definí FIREBASE_WEB_API_KEY en .env)")
req = urllib.request.Request(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={key}",
    data=json.dumps({"email": sys.argv[1], "password": sys.argv[2],
                     "returnSecureToken": True}).encode(),
    headers={"Content-Type": "application/json"},
)
try:
    print(json.load(urllib.request.urlopen(req))["idToken"])
except urllib.error.HTTPError as e:
    try:
        motivo = json.load(e)["error"]["message"]
    except Exception:  # noqa: BLE001
        motivo = str(e)
    sys.exit(f"Firebase respondió: {motivo}")
except Exception as e:  # noqa: BLE001
    sys.exit(f"No se pudo obtener el token: {e}")