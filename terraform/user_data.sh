#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================"
echo "SKS Hospital Application Setup"
echo "Started: $(date)"
echo "========================================"

echo "[1/10] Updating system packages..."
yum update -y

echo "[2/10] Installing Python 3.8..."
amazon-linux-extras install python3.8 -y
yum install git -y
python3.8 --version

echo "[3/10] Installing PostgreSQL client..."
amazon-linux-extras install postgresql14 -y

echo "[4/10] Creating application directory..."
mkdir -p /home/ec2-user/hospital-app
cd /home/ec2-user/hospital-app

echo "[5/10] Creating Python virtual environment..."
python3.8 -m venv venv
source venv/bin/activate
python --version

echo "[6/10] Creating requirements.txt..."
cat > requirements.txt << 'EOFREQ'
${requirements}
EOFREQ

echo "[7/10] Installing Python packages..."
pip install --upgrade pip
pip install -r requirements.txt
python -c "import flask; print('Flask version:', flask.__version__)"

echo "[8/10] Creating environment configuration..."
cat > .env << EOFENV
FLASK_APP=app.py
FLASK_ENV=production
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_host}:${db_port}/${db_name}
LOG_LEVEL=INFO
PORT=5000
EOFENV

echo "[9/10] Creating application files..."

cat > config.py << 'EOFCONFIG'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
    }
    HOSPITAL_NAME = "SKS Medical Center"
    HOSPITAL_LOCATION = "Bengaluru, Karnataka, India"
EOFCONFIG

echo "Waiting for database to be ready..."
for i in {1..30}; do
    if pg_isready -h ${db_host} -p ${db_port} -U ${db_username}; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting... attempt $i/30"
    sleep 10
done

cat > models.py << 'EOFMODELS'
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()

class Doctor(UserMixin, db.Model):
    __tablename__ = 'doctors'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    name = db.Column(db.String(100), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    specialization = db.Column(db.String(100))
    contact = db.Column(db.String(20))
    email = db.Column(db.String(120))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    patients = db.relationship('Patient', backref='doctor', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<Doctor {self.username}>'

class Patient(db.Model):
    __tablename__ = 'patients'
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    contact_number = db.Column(db.String(20), nullable=False, index=True)
    email = db.Column(db.String(100))
    address = db.Column(db.Text)
    blood_group = db.Column(db.String(5))
    medical_history = db.Column(db.Text)
    allergies = db.Column(db.Text)
    current_medications = db.Column(db.Text)
    emergency_contact_name = db.Column(db.String(100))
    emergency_contact_number = db.Column(db.String(20))
    registered_by = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    @property
    def age(self):
        today = datetime.today()
        return today.year - self.date_of_birth.year - ((today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day))
    
    def __repr__(self):
        return f'<Patient {self.full_name}>'
EOFMODELS

cat > init_app.py << 'EOFINITAPP'
from app import app, db
from models import Doctor

def initialize_database():
    with app.app_context():
        db.create_all()
        doctors_data = [
            {'username': 'kaashvi', 'name': 'Dr. Kaashvi Srivastava', 'password': 'kaashvi123', 
             'specialization': 'General Medicine', 'contact': '+91-9876543210', 'email': 'kaashvi@sksmedical.com'},
            {'username': 'yuvaan', 'name': 'Dr. Yuvaan Srivastava', 'password': 'yuvaan123', 
             'specialization': 'Pediatrics', 'contact': '+91-9876543211', 'email': 'yuvaan@sksmedical.com'},
            {'username': 'karthik', 'name': 'Dr. Karthik', 'password': 'karthik123', 
             'specialization': 'Cardiology', 'contact': '+91-9876543212', 'email': 'karthik@sksmedical.com'},
            {'username': 'omkar', 'name': 'Dr. Omkar', 'password': 'omkar123', 
             'specialization': 'Orthopedics', 'contact': '+91-9876543213', 'email': 'omkar@sksmedical.com'}
        ]
        for doc_data in doctors_data:
            existing = Doctor.query.filter_by(username=doc_data['username']).first()
            if not existing:
                doctor = Doctor(username=doc_data['username'], name=doc_data['name'], 
                              specialization=doc_data['specialization'], 
                              contact=doc_data['contact'], email=doc_data['email'])
                doctor.set_password(doc_data['password'])
                db.session.add(doctor)
        db.session.commit()
        print("Database initialized with 4 doctors!")

if __name__ == '__main__':
    initialize_database()
EOFINITAPP

cat > app.py << 'EOFAPP'
from flask import Flask, render_template, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from config import Config
from models import db, Doctor, Patient
from datetime import datetime
import os

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Please log in to access this page.'
login_manager.login_message_category = 'info'

@login_manager.user_loader
def load_user(user_id):
    return Doctor.query.get(int(user_id))

@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        if not username or not password:
            flash('Please enter both username and password', 'warning')
            return render_template('login.html')
        doctor = Doctor.query.filter_by(username=username).first()
        if doctor and doctor.check_password(password):
            login_user(doctor)
            flash(f'Welcome back, {doctor.name}!', 'success')
            next_page = request.args.get('next')
            return redirect(next_page) if next_page else redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    total_patients = Patient.query.count()
    my_patients = Patient.query.filter_by(registered_by=current_user.id).count()
    recent_patients = Patient.query.order_by(Patient.created_at.desc()).limit(5).all()
    return render_template('dashboard.html', total_patients=total_patients, 
                         my_patients=my_patients, recent_patients=recent_patients)

@app.route('/patients')
@login_required
def patients():
    sq = request.args.get('search', '').strip()
    if sq:
        search_pattern = '%' + sq + '%'
        patients_list = Patient.query.filter(db.or_(Patient.first_name.ilike(search_pattern), 
                                                      Patient.last_name.ilike(search_pattern), 
                                                      Patient.contact_number.ilike(search_pattern))).order_by(Patient.created_at.desc()).all()
    else:
        patients_list = Patient.query.order_by(Patient.created_at.desc()).all()
    return render_template('patients.html', patients=patients_list, search_query=sq)

@app.route('/patients/new', methods=['GET', 'POST'])
@login_required
def new_patient():
    if request.method == 'POST':
        try:
            dob_str = request.form.get('date_of_birth')
            dob = datetime.strptime(dob_str, '%Y-%m-%d').date() if dob_str else None
            patient = Patient(first_name=request.form.get('first_name', '').strip(), 
                            last_name=request.form.get('last_name', '').strip(), date_of_birth=dob, 
                            gender=request.form.get('gender'), 
                            contact_number=request.form.get('contact_number', '').strip(), 
                            email=request.form.get('email', '').strip() or None, 
                            address=request.form.get('address', '').strip() or None, 
                            blood_group=request.form.get('blood_group') or None, 
                            medical_history=request.form.get('medical_history', '').strip() or None, 
                            allergies=request.form.get('allergies', '').strip() or None, 
                            current_medications=request.form.get('current_medications', '').strip() or None, 
                            emergency_contact_name=request.form.get('emergency_contact_name', '').strip() or None, 
                            emergency_contact_number=request.form.get('emergency_contact_number', '').strip() or None, 
                            registered_by=current_user.id)
            db.session.add(patient)
            db.session.commit()
            flash(f'Patient {patient.full_name} registered successfully!', 'success')
            return redirect(url_for('patient_detail', patient_id=patient.id))
        except Exception as e:
            db.session.rollback()
            flash(f'Error registering patient: {str(e)}', 'danger')
    return render_template('patient_form.html', patient=None)

@app.route('/patients/<int:patient_id>')
@login_required
def patient_detail(patient_id):
    patient = Patient.query.get_or_404(patient_id)
    return render_template('patient_detail.html', patient=patient)

@app.route('/patients/<int:patient_id>/edit', methods=['GET', 'POST'])
@login_required
def edit_patient(patient_id):
    patient = Patient.query.get_or_404(patient_id)
    if request.method == 'POST':
        try:
            dob_str = request.form.get('date_of_birth')
            patient.date_of_birth = datetime.strptime(dob_str, '%Y-%m-%d').date() if dob_str else None
            patient.first_name = request.form.get('first_name', '').strip()
            patient.last_name = request.form.get('last_name', '').strip()
            patient.gender = request.form.get('gender')
            patient.contact_number = request.form.get('contact_number', '').strip()
            patient.email = request.form.get('email', '').strip() or None
            patient.address = request.form.get('address', '').strip() or None
            patient.blood_group = request.form.get('blood_group') or None
            patient.medical_history = request.form.get('medical_history', '').strip() or None
            patient.allergies = request.form.get('allergies', '').strip() or None
            patient.current_medications = request.form.get('current_medications', '').strip() or None
            patient.emergency_contact_name = request.form.get('emergency_contact_name', '').strip() or None
            patient.emergency_contact_number = request.form.get('emergency_contact_number', '').strip() or None
            patient.updated_at = datetime.utcnow()
            db.session.commit()
            flash(f'Patient {patient.full_name} updated successfully!', 'success')
            return redirect(url_for('patient_detail', patient_id=patient.id))
        except Exception as e:
            db.session.rollback()
            flash(f'Error updating patient: {str(e)}', 'danger')
    return render_template('patient_form.html', patient=patient)

@app.errorhandler(404)
def not_found_error(error):
    flash('Page not found.', 'warning')
    return redirect(url_for('dashboard'))

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    flash('An internal error occurred.', 'danger')
    return redirect(url_for('dashboard'))

if __name__ == '__main__':
    from init_app import initialize_database
    initialize_database()
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
EOFAPP

mkdir -p templates static/css static/js

cat > templates/login.html << 'EOFHTML'
<!DOCTYPE html>
<html><head><title>Login - SKS Medical Center</title></head>
<body style="font-family: Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center;">
<div style="background: white; padding: 40px; border-radius: 10px; max-width: 400px;">
<h1 style="text-align: center; color: #667eea;">SKS Medical Center</h1>
<p style="text-align: center; color: #666;">Templates will load after SCP deployment</p>
</div></body></html>
EOFHTML

echo "[10/10] Creating systemd service..."
cat > /etc/systemd/system/hospital-app.service << 'EOFSVC'
[Unit]
Description=SKS Hospital Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/hospital-app
Environment="PATH=/home/ec2-user/hospital-app/venv/bin"
ExecStart=/home/ec2-user/hospital-app/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 3 --timeout 120 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSVC

chown -R ec2-user:ec2-user /home/ec2-user/hospital-app

echo "Initializing database..."
cd /home/ec2-user/hospital-app
su - ec2-user -c "cd /home/ec2-user/hospital-app && source venv/bin/activate && python3 init_app.py" || true
sleep 10

systemctl daemon-reload
systemctl enable hospital-app
systemctl start hospital-app
sleep 3

echo "========================================"
echo "Setup Complete!"
echo "Date: $(date)"
echo "Python: $(python3.8 --version)"
echo "Service: $(systemctl is-active hospital-app)"
echo "========================================"