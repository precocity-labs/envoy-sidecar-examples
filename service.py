from flask import Flask
from flask import request
import socket
import os
import sys
import requests

app = Flask(__name__)

@app.route('/service/hello')
def hello():
    return ('Hello from behind Envoy (service {})! hostname: {} resolved'
            'hostname: {}\n'.format(os.environ['SERVICE_NAME'], 
                                    socket.gethostname(),
                                    socket.gethostbyname(socket.gethostname())))

@app.route('/service/pong')
def pong():
    return ("Ping from {}\n".format(os.environ['SERVICE_NAME']))

@app.route('/service/ping')
def ping():
    headers = {'Host': os.environ['SISTER_SERVICE_HOST']}
    resp = requests.get("{}/service/pong".format(os.environ["PONG_SERVICE_URL"]), headers=headers)
    return ('Pinged sister service and received response code of {} with response of {}\n'.format(resp.status_code, resp.text))


if __name__ == "__main__":
    app.run(host='127.0.0.1', port=os.environ['FLASK_PORT'], debug=True)
