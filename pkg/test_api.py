import requests

IMAGE_PATH = 'image.png'

API_URL = 'http://localhost:5000/predict'

with open(IMAGE_PATH, 'rb') as f:
    files = {'image': (IMAGE_PATH, f, 'image/jpeg')}

    try:
        response = requests.post(API_URL, files=files)

        print(response.json())

    except requests.exceptions.ConnectionError as e:
        print(f"Koneksi gagal: Pastikan server Flask (app.py) sudah berjalan.")
    except Exception as e:
        print(f"Error: {e}")