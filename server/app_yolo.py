import os
import io
from flask import Flask, request, jsonify
from ultralytics import YOLO
from PIL import Image 
import numpy as np

app = Flask(__name__)

try:
    model = YOLO("../model/traffic_sign.pt")
    print("Model YOLOv8 berhasil dimuat.")
except Exception as e:
    print(f"Error memuat model: {e}")
    model = None

@app.route('/predict', methods=['POST'])
def predict():
    """Endpoint untuk prediksi gambar."""
    
    if model is None:
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

            results = model.predict(source=pil_image, conf=0.5)

            output_data = []
            
            result = results[0] 
            
            for box in result.boxes:
                xyxy = box.xyxy[0].tolist() 
                conf = box.conf[0].item()   
                cls_id = int(box.cls[0].item()) 
                
                cls_name = model.names[cls_id] 
                
                output_data.append({
                    "class_name": cls_name,
                    "class_id": cls_id,
                    "confidence": conf,
                    "box_xyxy": xyxy
                })

            return jsonify(output_data)

        except Exception as e:
            return jsonify({"error": f"Error saat memproses gambar: {e}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)