import cv2
import joblib
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO
from PIL import Image
from skimage.color import rgb2gray
from skimage.feature import hog
import io
import warnings

warnings.filterwarnings('ignore')

app = Flask(__name__)
CORS(app)

SVM_MODEL_PATH = 'svm_traffic_sign_model.pkl'
RF_MODEL_PATH = 'rf_traffic_sign_model.pkl'
YOLO_MODEL_PATH = 'traffic_sign.pt'
LABEL_PATH = 'list_labelv2.txt'
IMG_SIZE = (64, 64)

try:
    svm_model = joblib.load(SVM_MODEL_PATH)
    rf_model = joblib.load(RF_MODEL_PATH)
    yolo_model = YOLO(YOLO_MODEL_PATH)
    yolo_model.to('cpu')

    with open(LABEL_PATH, 'r') as f:
        list_label = [line.strip() for line in f.readlines()]

except Exception as e:
    svm_model = rf_model = yolo_model = None
    list_label = []

def preprocess_image_for_prediction(img_bytes):
    nparr = np.frombuffer(img_bytes, np.uint8)
    img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    resized = cv2.resize(img_bgr, IMG_SIZE)
    gray = rgb2gray(cv2.cvtColor(resized, cv2.COLOR_BGR2RGB))

    hog_features = hog(
        gray,
        pixels_per_cell=(8, 8),
        cells_per_block=(2, 2),
        orientations=9
    )

    hsv = cv2.cvtColor(resized, cv2.COLOR_BGR2HSV)
    hist = cv2.calcHist([hsv], [0, 1], None, [16, 8], [0, 180, 0, 256])
    cv2.normalize(hist, hist)

    return np.concatenate([hog_features, hist.flatten()]).reshape(1, -1)

def label_decoder(idx):
    return list_label[idx] if idx < len(list_label) else "Unknown"

@app.route('/predict-svm', methods=['POST'])
def predict_svm():
    image = request.files.get('image')
    features = preprocess_image_for_prediction(image.read())
    idx = int(svm_model.predict(features)[0])
    conv = svm_model.predict_proba(features)[0][idx] * 100

    if conv < 75:
        return jsonify({
            'success': False,
            'message': 'Prediction confidence too low'
        })
    else:
        return jsonify({
        'success': True,
        'prediction': {
            'label_name': label_decoder(idx),
            'label_index': idx,
            'confidence': conv
            }
        })

@app.route('/predict-rf', methods=['POST'])
def predict_rf():
    image = request.files.get('image')
    features = preprocess_image_for_prediction(image.read())
    idx = int(rf_model.predict(features)[0])
    conv = rf_model.predict_proba(features)[0][idx] * 100
    if conv < 75:
        return jsonify({
            'success': False,
            'message': 'Prediction confidence too low'
        })
    else:
        return jsonify({
        'success': True,
        'prediction': {
            'label_name': label_decoder(idx),
            'label_index': idx,
            'confidence': conv
            }
        })

@app.route('/predict-yolo', methods=['POST'])
def predict_yolo():
    image = Image.open(io.BytesIO(request.files['image'].read()))
    results = yolo_model(image, conf=0.8)[0]

    output = []
    for box in results.boxes:
        output.append({
            "class_name": yolo_model.names[int(box.cls[0])],
            "class_id": int(box.cls[0]),
            "confidence": float(box.conf[0]),
            "box_xyxy": box.xyxy[0].tolist()
        })
    return jsonify(output)
            
@app.route('/login', methods=['POST'])
def login():
    username = request.form.get('username')
    password = request.form.get('password')

    if username == 'user' and password == '123': 
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'token': 'mock-auth-token-12345'
        }), 200
    else:
        return jsonify({
            'success': False,
            'message': 'Invalid username or password'
        }), 401 
    
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "API running",
        "endpoints": [
            "/predict-svm",
            "/predict-rf",
            "/predict-yolo",
            "/login"
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7860)
