import os
import cv2
import joblib
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO
from PIL import Image 
from scipy.signal import convolve2d
from skimage.color import rgb2gray
from skimage.feature import hog
import io
import warnings

app = Flask(__name__)
CORS(app)  # Enable CORS untuk semua routes
warnings.filterwarnings('ignore')

SVM_MODEL_PATH = '../model/v3/svm_traffic_sign_model.pkl'
RF_MODEL_PATH = '../model/v3/rf_traffic_sign_model.pkl'
YOLO_MODEL_PATh = '../model/v3/traffic_sign.pt'
LABEL_PATH = '../pkg/list_labelv2.txt'
IMG_SIZE = (64, 64)

try:
    svm_model = joblib.load(SVM_MODEL_PATH)
    print(f"* Model '{SVM_MODEL_PATH}' berhasil dimuat.")
    rf_model = joblib.load(RF_MODEL_PATH)
    print(f"* Model '{RF_MODEL_PATH}' berhasil dimuat.")
    yolo_model = YOLO(YOLO_MODEL_PATh)
    print(f"* Model '{YOLO_MODEL_PATh}' berhasil dimuat.")
    with open(LABEL_PATH, 'r') as f:
        list_label = [line.strip() for line in f.readlines()]
    print(f"* {len(list_label)} label berhasil dimuat.")

except FileNotFoundError as e:
    print(f"ERROR: Gagal memuat file penting: {e}")
    print("Pastikan 'svm_traffic_sign_model.pkl', 'rf_traffic_sign_model.pkl' dan 'list_label.txt' ada di folder yang sama.")
    svm_model = None
    rf_model = None
    yolo_model = None
    list_label = []
except Exception as e:
    print(f"Error saat memuat model atau label: {e}")
    svm_model = None
    rf_model = None
    yolo_model = None
    list_label = []


def preprocess_image_for_prediction(img_bytes):
    """
    Melakukan preprocessing HYBRID (HOG + Color) pada gambar yang di-upload.
    Ini HARUS SAMA PERSIS dengan script training.
    """
    try:
        nparr = np.frombuffer(img_bytes, np.uint8)
        img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        resized_img_bgr = cv2.resize(img_bgr, IMG_SIZE)
        resized_img_rgb = cv2.cvtColor(resized_img_bgr, cv2.COLOR_BGR2RGB)

        gray_image = rgb2gray(resized_img_rgb)
        hog_features = hog(gray_image, pixels_per_cell=(8, 8), cells_per_block=(2, 2), orientations=9, visualize=False)
        
        hsv_image = cv2.cvtColor(resized_img_bgr, cv2.COLOR_BGR2HSV)
        color_hist = cv2.calcHist([hsv_image], [0, 1], None, 
                                  [16, 8], [0, 180, 0, 256])
        cv2.normalize(color_hist, color_hist, alpha=0, beta=1, norm_type=cv2.NORM_MINMAX)
   
        color_features = color_hist.flatten()
        
        final_features = np.concatenate([hog_features, color_features])
        
        return final_features.reshape(1, -1)

    except Exception as e:
        print(f"Error saat preprocessing: {e}")
        return None

def label_decoder(label_index):
    """Mengubah index (angka) kembali menjadi nama rambu (string)"""
    try:
        return list_label[label_index]
    except:
        return "Label tidak dikenal"

@app.route('/predict-svm', methods=['POST'])
def predict_svm():
    if svm_model is None:
        return jsonify({'error': 'Model tidak dapat dimuat.'}), 500

    if 'image' not in request.files:
        return jsonify({'error': 'Request tidak berisi file gambar.'}), 400
        
    file = request.files['image']
    
    if file.filename == '':
        return jsonify({'error': 'Nama file kosong.'}), 400
        
    try:
        img_bytes = file.read()
        
        features = preprocess_image_for_prediction(img_bytes)
        
        if features is None:
            return jsonify({'error': 'Gagal memproses gambar.'}), 400

        prediction_index = svm_model.predict(features)[0]
        prediction_name = label_decoder(int(prediction_index))
        
        return jsonify({
            'success': True,
            'prediction': {
                'label_name': prediction_name,
                'label_index': int(prediction_index)
            }
        })

    except Exception as e:
        return jsonify({'error': f'Terjadi kesalahan: {str(e)}'}), 500
    
@app.route('/predict-rf', methods=['POST'])
def predict_rf():
    if rf_model is None:
        return jsonify({'error': 'Model tidak dapat dimuat.'}), 500

    if 'image' not in request.files:
        return jsonify({'error': 'Request tidak berisi file gambar.'}), 400
        
    file = request.files['image']
    
    if file.filename == '':
        return jsonify({'error': 'Nama file kosong.'}), 400
        
    try:
        img_bytes = file.read()
        
        features = preprocess_image_for_prediction(img_bytes)
        
        if features is None:
            return jsonify({'error': 'Gagal memproses gambar.'}), 400

        prediction_index = rf_model.predict(features)[0]
        prediction_name = label_decoder(int(prediction_index))
        
        return jsonify({
            'success': True,
            'prediction': {
                'label_name': prediction_name,
                'label_index': int(prediction_index)
            }
        })

    except Exception as e:
        return jsonify({'error': f'Terjadi kesalahan: {str(e)}'}), 500


@app.route('/predict-yolo', methods=['POST'])
def predict():    
    if yolo_model is None:
        return jsonify({"error": "Model tidak berhasil dimuat"}), 500

    if 'image' not in request.files:
        return jsonify({"error": "Tidak ada file 'image' dalam request"}), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({"error": "Tidak ada file yang dipilih"}), 400

    if file:
        try:
            image_bytes = file.read()
            pil_image = Image.open(io.BytesIO(image_bytes))

            results = yolo_model.predict(source=pil_image, conf=0.8)

            output_data = []
            
            result = results[0] 
            
            for box in result.boxes:
                xyxy = box.xyxy[0].tolist() 
                conf = box.conf[0].item()   
                cls_id = int(box.cls[0].item()) 
                
                cls_name = yolo_model.names[cls_id] 
                
                output_data.append({
                    "class_name": cls_name,
                    "class_id": cls_id,
                    "confidence": conf,
                    "box_xyxy": xyxy
                })

            return jsonify(output_data)

        except Exception as e:
            return jsonify({"error": f"Error saat memproses gambar: {e}"}), 500
            
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)