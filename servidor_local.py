import http.server
import socketserver
import json
import os
from pymongo import MongoClient

PORT = 8000
DIRECTORY = os.path.dirname(os.path.abspath(__file__))
MONGO_URI = "mongodb+srv://eduaranguiz_db_user:BCxgtQ2QMAj1X8ks@cluster0.zx199lj.mongodb.net/?retryWrites=true&w=majority"

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        if self.path == '/api/mongodb-productos':
            self.handle_mongodb_api()
        else:
            super().do_GET()

    def handle_mongodb_api(self):
        try:
            client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
            db = client["estilo_urbano_nosql"]
            docs = list(db.productos.find({}))
            # Serialize
            for doc in docs:
                doc['_id'] = str(doc['_id'])
                if 'fecha_creacion' in doc:
                    doc['fecha_creacion'] = doc['fecha_creacion'].isoformat()
                if 'fecha_actualizacion' in doc:
                    doc['fecha_actualizacion'] = doc['fecha_actualizacion'].isoformat()
                if 'fecha_baja' in doc:
                    doc['fecha_baja'] = doc['fecha_baja'].isoformat()
            
            payload = json.dumps(docs).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', len(payload))
            self.end_headers()
            self.wfile.write(payload)
        except Exception as e:
            err = json.dumps({"error": str(e)}).encode('utf-8')
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', len(err))
            self.end_headers()
            self.wfile.write(err)

def run():
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        print(f"================================================================")
        print(f"  SERVIDOR ESTILO URBANO CONECTADO A MONGODB ATLAS (NUBE)")
        print(f"  Abre en tu navegador: http://localhost:{PORT}")
        print(f"================================================================")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor detenido.")

if __name__ == '__main__':
    run()
