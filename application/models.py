from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()

class Doctor(UserMixin, db.Model):
    """Doctor model for authentication and patient management"""
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
    
    # Relationship with patients
    patients = db.relationship('Patient', backref='doctor', lazy='dynamic')
    
    def set_password(self, password):
    # Use pbkdf2:sha256 instead of default scrypt
    self.password_hash = generate_password_hash(password, method='pbkdf2:sha256')
    
    def check_password(self, password):
        """Verify password"""
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<Doctor {self.username}>'

class Patient(db.Model):
    """Patient model for storing patient information"""
    __tablename__ = 'patients'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Personal Information
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    blood_group = db.Column(db.String(5))
    
    # Contact Information
    contact_number = db.Column(db.String(20), nullable=False, index=True)
    email = db.Column(db.String(100))
    address = db.Column(db.Text)
    
    # Medical Information
    medical_history = db.Column(db.Text)
    allergies = db.Column(db.Text)
    current_medications = db.Column(db.Text)
    
    # Emergency Contact
    emergency_contact_name = db.Column(db.String(100))
    emergency_contact_number = db.Column(db.String(20))
    
    # Registration Information
    registered_by = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    @property
    def full_name(self):
        """Return full name of patient"""
        return f"{self.first_name} {self.last_name}"
    
    @property
    def age(self):
        """Calculate and return age from date of birth"""
        today = datetime.today()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )
    
    def __repr__(self):
        return f'<Patient {self.full_name}>'

# Future models for Phase 2 and 3

class Pharmacy(db.Model):
    """Pharmacy model for storing pharmacy information (Phase 2)"""
    __tablename__ = 'pharmacies'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.Text, nullable=False)
    contact_number = db.Column(db.String(20), nullable=False)
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    operating_hours = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Pharmacy {self.name}>'

class Medicine(db.Model):
    """Medicine model for storing medicine information (Phase 2)"""
    __tablename__ = 'medicines'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, index=True)
    generic_name = db.Column(db.String(200))
    description = db.Column(db.Text)
    dosage_form = db.Column(db.String(50))  # Tablet, Capsule, Syrup, etc.
    strength = db.Column(db.String(50))
    manufacturer = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Medicine {self.name}>'

class Prescription(db.Model):
    """Prescription model for storing patient prescriptions (Phase 2)"""
    __tablename__ = 'prescriptions'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    medicine_id = db.Column(db.Integer, db.ForeignKey('medicines.id'), nullable=False)
    dosage = db.Column(db.String(100), nullable=False)
    frequency = db.Column(db.String(100), nullable=False)
    duration = db.Column(db.String(50), nullable=False)
    instructions = db.Column(db.Text)
    prescribed_date = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    patient = db.relationship('Patient', backref='prescriptions')
    prescribed_by = db.relationship('Doctor', backref='prescriptions')
    medicine = db.relationship('Medicine', backref='prescriptions')
    
    def __repr__(self):
        return f'<Prescription {self.id} for Patient {self.patient_id}>'