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

SVM_MODEL_PATH = '../model/svm_traffic_sign_model.pkl'
RF_MODEL_PATH = '../model/rf_traffic_sign_model.pkl'
YOLO_MODEL_PATh = '../model/traffic_sign.pt'
LABEL_PATH = '../pkg/list_label.txt'
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

# def get_gradients(gray_image):
#     """Menghitung magnitudo dan orientasi gradien."""
#     sobel_x = np.array([[-1, 0, 1],
#                         [-2, 0, 2],
#                         [-1, 0, 1]])
    
#     sobel_y = np.array([[-1, -2, -1],
#                         [ 0,  0,  0],
#                         [ 1,  2,  1]])
    
#     Gx = convolve2d(gray_image, sobel_x, mode='same', boundary='symm')
#     Gy = convolve2d(gray_image, sobel_y, mode='same', boundary='symm')
    
#     magnitude = np.sqrt(Gx**2 + Gy**2)
#     orientation_rad = np.arctan2(Gy, Gx)

#     orientation_deg = np.degrees(orientation_rad) % 180
    
#     return magnitude, orientation_deg

# def manual_hog_extractor(gray_image, pixels_per_cell=(8, 8), cells_per_block=(2, 2), n_bins=9):
#     """
#     Mengimplementasikan HOG secara manual menggunakan NumPy.
    
#     Langkah 1: Menghitung gradien (magnitudo & orientasi).
#     Langkah 2: Membuat histogram orientasi untuk setiap 'cell'.
#     Langkah 3 & 4: Normalisasi histogram dalam 'block' yang tumpang tindih.
#     Langkah 5: Menggabungkan semua vektor blok menjadi satu vektor fitur.
#     """
    
#     magnitude, orientation = get_gradients(gray_image)
    
#     img_h, img_w = gray_image.shape
#     cell_h, cell_w = pixels_per_cell
#     block_h, block_w = cells_per_block
    
#     n_cells_y = img_h // cell_h 
#     n_cells_x = img_w // cell_w 
    
#     bin_size = 180.0 / n_bins

#     cell_histograms = np.zeros((n_cells_y, n_cells_x, n_bins))
    
#     for y in range(n_cells_y):
#         for x in range(n_cells_x):
#             cell_y_start = y * cell_h
#             cell_y_end = (y + 1) * cell_h
#             cell_x_start = x * cell_w
#             cell_x_end = (x + 1) * cell_w
            
#             magnitude_cell = magnitude[cell_y_start:cell_y_end, cell_x_start:cell_x_end]
#             orientation_cell = orientation[cell_y_start:cell_y_end, cell_x_start:cell_x_end]
            
#             hist = np.zeros(n_bins)
            
#             for r in range(cell_h):
#                 for c in range(cell_w):
#                     mag = magnitude_cell[r, c]
#                     ori = orientation_cell[r, c]
                    
#                     bin_idx_float = ori / bin_size
#                     bin_1 = int(np.floor(bin_idx_float - 0.5)) 
#                     bin_2 = int(np.floor(bin_idx_float + 0.5))
                    
#                     weight_2 = (bin_idx_float - (bin_1 + 0.5))
#                     weight_1 = 1.0 - weight_2
                    
#                     hist[bin_1 % n_bins] += weight_1 * mag
#                     hist[bin_2 % n_bins] += weight_2 * mag
                    
#             cell_histograms[y, x, :] = hist
            
    
#     n_blocks_y = n_cells_y - block_h + 1 
#     n_blocks_x = n_cells_x - block_w + 1 
    
#     all_blocks_list = []
    
#     epsilon = 1e-5
    
#     for by in range(n_blocks_y):
#         for bx in range(n_blocks_x):

#             block = cell_histograms[by : by + block_h, 
#                                     bx : bx + block_w, 
#                                     :]

#             block_vector = block.ravel()
            
#             norm = np.sqrt(np.sum(block_vector**2) + epsilon)
#             block_normalized = block_vector / norm
            
#             all_blocks_list.append(block_normalized)
            
#     final_feature_vector = np.concatenate(all_blocks_list)
    
#     return final_feature_vector


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