from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
import uuid
import json
from fpdf import FPDF

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///rehabilitation.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'your_secret_key'

db = SQLAlchemy(app)
jwt = JWTManager(app)

class User(db.Model):
    id = db.Column(db.String(50), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="patient")

class Exercise(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    image = db.Column(db.String(255), nullable=True)
    repetitions = db.Column(db.Integer, nullable=False)
    patient_id = db.Column(db.String(50), db.ForeignKey('user.id'), nullable=False)

class GeneralExercise(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    video_url = db.Column(db.String(255), nullable=True)

class ExercisesToDo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), db.ForeignKey('user.id'), nullable=False)
    date = db.Column(db.String(50), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    repetitions = db.Column(db.Integer, nullable=False)
    sets = db.Column(db.Integer, nullable=False)
    weight = db.Column(db.Float, nullable=True)
    rest_time = db.Column(db.Integer, nullable=False)
    completion_state = db.Column(db.Text, nullable=False)

with app.app_context():
    db.create_all()

@app.route("/register", methods=["POST"])
def register():
    try:
        data = request.json
        name = data.get("name")
        email = data.get("email")
        password = data.get("password")
        role = data.get("role", "patient")

        if not name or not email or not password:
            return jsonify({"error": "Missing required fields"}), 400

        if role not in ["patient", "therapist"]:
            return jsonify({"error": "Invalid role"}), 400


        if User.query.filter_by(email=email).first():
            return jsonify({"error": "User already exists"}), 400


        password_hash = generate_password_hash(password)
        new_user = User(name=name, email=email, password_hash=password_hash, role=role)

        db.session.add(new_user)
        db.session.commit()

        return jsonify({"message": "User registered successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/login", methods=["POST"])
def login():
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")


        user = User.query.filter_by(email=email).first()
        if not user or not check_password_hash(user.password_hash, password):
            return jsonify({"error": "Invalid email or password"}), 401


        identity = json.dumps({"id": user.id, "role": user.role})
        access_token = create_access_token(identity=identity)
        return jsonify({"access_token": access_token, "role": user.role}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/get_users", methods=["GET"])
@jwt_required()
def get_users():
    try:
        current_user = json.loads(get_jwt_identity())
        if current_user["role"] != "therapist":
            return jsonify({"error": "Unauthorized"}), 403

        users = User.query.filter_by(role="patient").all()
        user_list = [
            {
                "id": user.id,
                "name": user.name,
                "email": user.email
            }
            for user in users
        ]
        return jsonify({"users": user_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/add_exercise", methods=["POST"])
@jwt_required()
def add_exercise():
    try:
        data = request.json
        name = data.get("name")
        description = data.get("description")
        image = data.get("image")
        repetitions = data.get("repetitions")
        patient_id = data.get("patient_id")

        if not name or not description or not repetitions or not patient_id:
            return jsonify({"error": "Missing required fields"}), 400

        new_exercise = Exercise(
            name=name,
            description=description,
            image=image,
            repetitions=repetitions,
            patient_id=patient_id
        )

        db.session.add(new_exercise)
        db.session.commit()

        return jsonify({"message": "Exercise added successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/add_general_exercise", methods=["POST"])
def add_general_exercise():
    try:
        data = request.json
        name = data.get("name")
        description = data.get("description")
        video_url = data.get("video_url")

        if not name or not description:
            return jsonify({"error": "Missing required fields"}), 400

        new_exercise = GeneralExercise(name=name, description=description, video_url=video_url)
        db.session.add(new_exercise)
        db.session.commit()

        return jsonify({"message": "Exercise added successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/get_general_exercises", methods=["GET"])
def get_general_exercises():
    try:
        exercises = GeneralExercise.query.all()
        exercise_list = [
            {
                "id": exercise.id,
                "name": exercise.name,
                "description": exercise.description,
                "video_url": exercise.video_url,
            }
            for exercise in exercises
        ]
        return jsonify({"exercises": exercise_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/update_general_exercise", methods=["PUT"])
def update_general_exercise():
    try:
        data = request.json
        exercise_id = data.get("id")
        new_video_url = data.get("video_url")

        if not exercise_id or not new_video_url:
            return jsonify({"error": "Missing required fields"}), 400

        exercise = GeneralExercise.query.get(exercise_id)
        if not exercise:
            return jsonify({"error": "Exercise not found"}), 404

        exercise.video_url = new_video_url
        db.session.commit()

        return jsonify({"message": "Video URL updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/add_exercise_todo", methods=["POST"])
@jwt_required()
def add_exercise_todo():
    try:
        current_user = json.loads(get_jwt_identity())
        if current_user["role"] != "therapist":
            return jsonify({"error": "Unauthorized"}), 403

        data = request.json
        user_id = data.get("user_id")
        date = data.get("date")
        name = data.get("name")
        repetitions = data.get("repetitions")
        sets = data.get("sets")
        weight = data.get("weight")
        rest_time = data.get("rest_time")

        if not all([user_id, date, name, repetitions, sets, rest_time]):
            return jsonify({"error": "Missing required fields"}), 400


        completion_state = [False] * sets

        new_exercise = ExercisesToDo(
            user_id=user_id,
            date=date,
            name=name,
            repetitions=repetitions,
            sets=sets,
            weight=weight,
            rest_time=rest_time,
            completion_state=json.dumps(completion_state)
        )

        db.session.add(new_exercise)
        db.session.commit()

        return jsonify({"message": "Exercise added successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/update_exercise_todo/<int:exercise_id>", methods=["PUT"])
@jwt_required()
def update_exercise_todo(exercise_id):
    try:
        current_user = json.loads(get_jwt_identity())
        if current_user["role"] != "therapist":
            return jsonify({"error": "Unauthorized"}), 403

        data = request.json
        exercise = ExercisesToDo.query.get(exercise_id)
        if not exercise:
            return jsonify({"error": "Exercise not found"}), 404


        exercise.name = data.get("name", exercise.name)
        exercise.repetitions = data.get("repetitions", exercise.repetitions)
        exercise.sets = data.get("sets", exercise.sets)
        exercise.weight = data.get("weight", exercise.weight)
        exercise.rest_time = data.get("rest_time", exercise.rest_time)
        exercise.completion_state = json.dumps(data.get("completion_state", json.loads(exercise.completion_state)))

        db.session.commit()
        return jsonify({"message": "Exercise updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/delete_exercise_todo/<int:exercise_id>", methods=["DELETE"])
@jwt_required()
def delete_exercise_todo(exercise_id):
    try:
        current_user = json.loads(get_jwt_identity())
        if current_user["role"] != "therapist":
            return jsonify({"error": "Unauthorized"}), 403

        exercise = ExercisesToDo.query.get(exercise_id)
        if not exercise:
            return jsonify({"error": "Exercise not found"}), 404

        db.session.delete(exercise)
        db.session.commit()
        return jsonify({"message": "Exercise deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/get_exercises/<user_id>", methods=["GET"])
@jwt_required()
def get_exercises(user_id):
    try:
        current_user = json.loads(get_jwt_identity())


        if current_user["role"] == "therapist":
            pass
        elif current_user["role"] == "patient":
            if user_id == "CURRENT_USER_ID":
                user_id = current_user["id"]
            if current_user["id"] != user_id:
                return jsonify({"error": "Unauthorized"}), 403
        else:
            return jsonify({"error": "Unauthorized"}), 403

        date = request.args.get("date")
        if not date:
            return jsonify({"error": "Missing date parameter"}), 400

        exercises = ExercisesToDo.query.filter_by(user_id=user_id, date=date).all()
        exercise_list = [
            {
                "id": exercise.id,
                "name": exercise.name,
                "repetitions": exercise.repetitions,
                "sets": exercise.sets,
                "weight": exercise.weight,
                "rest_time": exercise.rest_time,
                "completion_state": json.loads(exercise.completion_state)
            }
            for exercise in exercises
        ]

        return jsonify({"exercises": exercise_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/update_exercise_completion_state/<int:exercise_id>", methods=["PUT"])
@jwt_required()
def update_exercise_completion_state(exercise_id):
    try:
        data = request.json
        completion_state = data.get("completion_state")

        if not isinstance(completion_state, list):
            return jsonify({"error": "Invalid completion_state format"}), 422

        exercise = ExercisesToDo.query.get(exercise_id)
        if not exercise:
            return jsonify({"error": "Exercise not found"}), 404

        exercise.completion_state = json.dumps(completion_state)
        db.session.commit()

        return jsonify({"message": "Completion state updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/generate_report/<user_id>", methods=["GET"])
@jwt_required()
def generate_report(user_id):
    try:

        current_user = json.loads(get_jwt_identity())


        if current_user["role"] == "patient" and current_user["id"] != user_id:
            return jsonify({"error": "Unauthorized"}), 403


        if current_user["role"] == "therapist" or (current_user["role"] == "patient" and current_user["id"] == user_id):
            start_date = request.args.get("start_date")
            end_date = request.args.get("end_date")
            if not start_date or not end_date:
                return jsonify({"error": "Missing date parameters"}), 400

            exercises = ExercisesToDo.query.filter(
                ExercisesToDo.user_id == user_id,
                ExercisesToDo.date >= start_date,
                ExercisesToDo.date <= end_date
            ).all()

            if not exercises:
                return jsonify({"message": "No exercises found for the given date range."}), 404


            report_data = []
            for exercise in exercises:
                report_data.append({
                    "date": exercise.date,
                    "name": exercise.name,
                    "repetitions": exercise.repetitions,
                    "sets": exercise.sets,
                    "weight": exercise.weight,
                    "rest_time": exercise.rest_time,
                    "completion_state": json.loads(exercise.completion_state)
                })


            report_path = f"reports/report_{user_id}_{start_date}_to_{end_date}.txt"
            with open(report_path, "w") as report_file:
                for entry in report_data:
                    report_file.write(str(entry) + "\n")

            return jsonify({"file_path": report_path}), 200
        else:
            return jsonify({"error": "Unauthorized"}), 403
    except Exception as e:
        return jsonify({"error": str(e)}), 500





if __name__ == "__main__":
    app.run(debug=True)
