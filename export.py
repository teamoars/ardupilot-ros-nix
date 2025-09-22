from ultralytics import YOLO

# Load a model
model = YOLO('yolov8n.pt')

# Export to OpenVINO
model.export(format='openvino')
