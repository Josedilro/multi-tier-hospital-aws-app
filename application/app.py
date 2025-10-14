from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from config import Config
from models import db, Doctor, Patient
from datetime import datetime
import os
import logging

# Initialize Flask application
app = Flask(__name__)
app.config.from_object(Config)

# Initialize extensions
db.init_app(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Please log in to access this page.'
login_manager.login_message_category = 'info'

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@login_manager.user_loader
def load_user(user_id):
    """Load user by ID for Flask-Login"""
    return Doctor.query.get(int(user_id))

def init_database():
    """Initialize database and create default doctor accounts"""
    with app.app_context():
        # Create all tables
        db.create_all()
        logger.info("Database tables created successfully")
        
        # Create default doctor accounts if they don't exist
        default_doctors = [
            {
                'username': 'kaashvi',
                'name': 'Dr. Kaashvi Srivastava',
                'password': 'kaashvi123',
                'specialization': 'General Medicine',
                'contact': '+91-9876543210',
                'email': 'kaashvi@sksmedical.com'
            },
            {
                'username': 'yuvaan',
                'name': 'Dr. Yuvaan Srivastava',
                'password': 'yuvaan123',
                'specialization': 'Pediatrics',
                'contact': '+91-9876543211',
                'email': 'yuvaan@sksmedical.com'
            },
            {
                'username': 'karthik',
                'name': 'Dr. Karthik',
                'password': 'karthik123',
                'specialization': 'Cardiology',
                'contact': '+91-9876543212',
                'email': 'karthik@sksmedical.com'
            },
            {
                'username': 'omkar',
                'name': 'Dr. Omkar',
                'password': 'omkar123',
                'specialization': 'Orthopedics',
                'contact': '+91-9876543213',
                'email': 'omkar@sksmedical.com'
            }
        ]
        
        for doc_data in default_doctors:
            existing_doctor = Doctor.query.filter_by(username=doc_data['username']).first()
            if not existing_doctor:
                doctor = Doctor(
                    username=doc_data['username'],
                    name=doc_data['name'],
                    specialization=doc_data['specialization'],
                    contact=doc_data.get('contact'),
                    email=doc_data.get('email')
                )
                doctor.set_password(doc_data['password'])
                db.session.add(doctor)
                logger.info(f"Created doctor account: {doc_data['username']}")
        
        try:
            db.session.commit()
            logger.info("Database initialized successfully!")
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error initializing database: {str(e)}")

# Routes

@app.route('/')
def index():
    """Home page - redirect to dashboard if logged in, else login"""
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Doctor login page"""
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
            logger.info(f"Doctor logged in: {doctor.username}")
            flash(f'Welcome back, {doctor.name}!', 'success')
            
            # Redirect to next page if specified
            next_page = request.args.get('next')
            return redirect(next_page) if next_page else redirect(url_for('dashboard'))
        else:
            logger.warning(f"Failed login attempt for username: {username}")
            flash('Invalid username or password', 'danger')
    
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    """Logout current doctor"""
    logger.info(f"Doctor logged out: {current_user.username}")
    logout_user()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    """Dashboard page with statistics"""
    total_patients = Patient.query.count()
    my_patients = Patient.query.filter_by(registered_by=current_user.id).count()
    recent_patients = Patient.query.order_by(Patient.created_at.desc()).limit(5).all()
    
    return render_template('dashboard.html',
                         total_patients=total_patients,
                         my_patients=my_patients,
                         recent_patients=recent_patients)

@app.route('/patients')
@login_required
def patients():
    """Patient list page with search functionality"""
    search_query = request.args.get('search', '').strip()
    
    if search_query:
        # Search by first name, last name, or contact number
        patients_list = Patient.query.filter(
            db.or_(
                Patient.first_name.ilike(f'%{search_query}%'),
                Patient.last_name.ilike(f'%{search_query}%'),
                Patient.contact_number.ilike(f'%{search_query}%')
            )
        ).order_by(Patient.created_at.desc()).all()
        logger.info(f"Search performed: '{search_query}', results: {len(patients_list)}")
    else:
        patients_list = Patient.query.order_by(Patient.created_at.desc()).all()
    
    return render_template('patients.html', patients=patients_list, search_query=search_query)

@app.route('/patients/new', methods=['GET', 'POST'])
@login_required
def new_patient():
    """Add new patient"""
    if request.method == 'POST':
        try:
            # Parse date of birth
            dob_str = request.form.get('date_of_birth')
            dob = datetime.strptime(dob_str, '%Y-%m-%d').date() if dob_str else None
            
            if not dob:
                flash('Please provide a valid date of birth', 'danger')
                return render_template('patient_form.html', patient=None)
            
            patient = Patient(
                first_name=request.form.get('first_name', '').strip(),
                last_name=request.form.get('last_name', '').strip(),
                date_of_birth=dob,
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
                registered_by=current_user.id
            )
            
            db.session.add(patient)
            db.session.commit()
            
            logger.info(f"New patient registered: {patient.full_name} (ID: {patient.id})")
            flash(f'Patient {patient.full_name} registered successfully!', 'success')
            return redirect(url_for('patient_detail', patient_id=patient.id))
            
        except ValueError as e:
            flash('Invalid date format. Please use YYYY-MM-DD format.', 'danger')
            logger.error(f"Date parsing error: {str(e)}")
        except Exception as e:
            db.session.rollback()
            flash(f'Error registering patient: {str(e)}', 'danger')
            logger.error(f"Error creating patient: {str(e)}")
    
    return render_template('patient_form.html', patient=None)

@app.route('/patients/<int:patient_id>')
@login_required
def patient_detail(patient_id):
    """View patient details"""
    patient = Patient.query.get_or_404(patient_id)
    return render_template('patient_detail.html', patient=patient)

@app.route('/patients/<int:patient_id>/edit', methods=['GET', 'POST'])
@login_required
def edit_patient(patient_id):
    """Edit patient information"""
    patient = Patient.query.get_or_404(patient_id)
    
    if request.method == 'POST':
        try:
            # Parse date of birth
            dob_str = request.form.get('date_of_birth')
            dob = datetime.strptime(dob_str, '%Y-%m-%d').date() if dob_str else None
            
            if not dob:
                flash('Please provide a valid date of birth', 'danger')
                return render_template('patient_form.html', patient=patient)
            
            # Update patient information
            patient.first_name = request.form.get('first_name', '').strip()
            patient.last_name = request.form.get('last_name', '').strip()
            patient.date_of_birth = dob
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
            
            logger.info(f"Patient updated: {patient.full_name} (ID: {patient.id})")
            flash(f'Patient {patient.full_name} updated successfully!', 'success')
            return redirect(url_for('patient_detail', patient_id=patient.id))
            
        except ValueError as e:
            flash('Invalid date format. Please use YYYY-MM-DD format.', 'danger')
            logger.error(f"Date parsing error: {str(e)}")
        except Exception as e:
            db.session.rollback()
            flash(f'Error updating patient: {str(e)}', 'danger')
            logger.error(f"Error updating patient: {str(e)}")
    
    return render_template('patient_form.html', patient=patient)

# Error handlers

@app.errorhandler(404)
def not_found_error(error):
    """Handle 404 errors"""
    flash('The page you are looking for does not exist.', 'warning')
    return redirect(url_for('dashboard'))

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    db.session.rollback()
    logger.error(f"Internal server error: {str(error)}")
    flash('An internal error occurred. Please try again later.', 'danger')
    return redirect(url_for('dashboard'))

# Application startup

if __name__ == '__main__':
    init_database()
    
    # Run the application
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger.info(f"Starting SKS Medical Center application on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)