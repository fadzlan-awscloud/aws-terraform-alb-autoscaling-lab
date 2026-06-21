#!/bin/bash

sudo apt update -y
sudo apt install python3-pip python3-venv -y

python3 -m venv /home/ubuntu/flask_env
/home/ubuntu/flask_env/bin/pip install flask

cat > /home/ubuntu/app.py <<EOF
from flask import Flask
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    return f"Hello from {socket.gethostname()}!"

app.run(host='0.0.0.0', port=5000)
EOF

nohup /home/ubuntu/flask_env/bin/python3 /home/ubuntu/app.py &