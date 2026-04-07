# TB Detection AI

A web-based Tuberculosis detection system that uses machine learning to analyze chest X-ray images. Built with Django, MySQL, and a modern responsive frontend.

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-5.2-092E20?logo=django&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Setup](#database-setup)
- [Running the Server](#running-the-server)
- [Docker](#docker)
- [API Reference](#api-reference)
- [How It Works](#how-it-works)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Drag & Drop Upload** — Upload chest X-ray images via drag-and-drop or file browser
- **Real-time Preview** — Instant image preview before analysis
- **AI-Powered Prediction** — ML model classifies X-rays as *Tuberculosis Detected* or *Normal* (when model is enabled)
- **Confidence Score** — Displays prediction confidence percentage
- **MySQL Storage** — Every uploaded X-ray image is persisted in a MySQL database
- **Responsive Design** — Modern glassmorphism UI that works across desktop, tablet, and mobile
- **Accessible** — ARIA labels, keyboard navigation, and screen reader support
- **CSRF Protection** — Django's built-in CSRF middleware secures all POST requests

---

## Tech Stack

| Layer      | Technology                          |
|------------|-------------------------------------|
| Backend    | Python 3.11+, Django 5.2            |
| Database   | MySQL 8.0                           |
| ML         | Keras / scikit-learn (via `model.pkl`) |
| Frontend   | HTML5, CSS3 (custom properties), Vanilla JS |
| Imaging    | Pillow                              |
| Container  | Docker (Alpine-based)               |

---

## Project Structure

```
web_code/
└── core/                        # Django project root
    ├── manage.py                # Django CLI entry point
    ├── requirements.txt         # Python dependencies
    ├── Dockerfile               # Container build config
    ├── core/                    # Project settings package
    │   ├── settings.py          # Database, static, media config
    │   ├── urls.py              # Root URL routing
    │   ├── wsgi.py              # WSGI application
    │   └── asgi.py              # ASGI application
    └── main/                    # Primary Django app
        ├── models.py            # XRayImage model (MySQL)
        ├── views.py             # index + predict views
        ├── urls.py              # App-level routes
        ├── admin.py             # Admin registration
        ├── apps.py              # App config
        ├── tests.py             # Test suite
        ├── templates/
        │   └── index.html       # Upload UI template
        └── static/
            ├── style.css        # Glassmorphism styles
            └── script.js        # Upload, preview, fetch logic
```

---

## Prerequisites

- **Python** 3.11 or higher
- **MySQL** 8.0 or higher (running locally or remotely)
- **pip** (Python package manager)
- *(Optional)* **Docker** for containerized deployment

---

## Installation

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd Web_X_ray/web_code/core
```

### 2. Create a virtual environment

```bash
python -m venv venv
```

**Activate it:**

- **Windows (PowerShell):**
  ```powershell
  .\venv\Scripts\Activate
  ```
- **macOS / Linux:**
  ```bash
  source venv/bin/activate
  ```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

> **Note:** `mysqlclient` requires MySQL C client libraries. On Windows, the pre-built wheel is used automatically. On Linux, you may need `sudo apt install libmysqlclient-dev`.

---

## Database Setup

### 1. Create the MySQL database

Open a MySQL shell and run:

```sql
CREATE DATABASE web_xray_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Configure credentials

Edit `core/settings.py` and update the `DATABASES` section with your MySQL credentials:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'web_xray_db',
        'USER': 'root',            # your MySQL username
        'PASSWORD': 'yourpassword', # your MySQL password
        'HOST': '127.0.0.1',
        'PORT': '3306',
        'OPTIONS': {
            'charset': 'utf8mb4',
        },
    }
}
```

### 3. Run migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

This creates the `xray_images` table along with Django's default tables (auth, sessions, etc.).

### 4. Create a superuser *(optional, for admin panel)*

```bash
python manage.py createsuperuser
```

---

## Running the Server

```bash
python manage.py runserver
```

Open your browser at **http://127.0.0.1:8000** and you'll see the TB Detection AI interface.

---

## Docker

Build and run with Docker:

```bash
cd web_code/core

docker build -t tb-detection-ai .
docker run -p 8000:8000 tb-detection-ai
```

> **Note:** The Dockerfile currently installs only Django. For full functionality (MySQL, Pillow, ML libraries), update the `RUN pip install` line in `Dockerfile` to `pip install -r requirements.txt`.

---

## API Reference

### `GET /`

Renders the X-ray upload page.

### `POST /predict/`

Upload a chest X-ray image for storage (and prediction when the ML model is enabled).

**Request:**

| Field   | Type   | Description              |
|---------|--------|--------------------------|
| `image` | File   | Chest X-ray image file   |

**Headers:**

| Header        | Value                     |
|---------------|---------------------------|
| `X-CSRFToken` | CSRF token from cookie    |

**Success Response (200):**

```json
{
  "message": "Image saved successfully.",
  "image_id": 1,
  "image_url": "/media/xray_images/chest_xray.png"
}
```

**With ML model enabled:**

```json
{
  "prediction": "Tuberculosis Detected",
  "class": 1,
  "confidence": 0.9732
}
```

**Error Response (400):**

```json
{
  "error": "No image uploaded."
}
```

---

## How It Works

```
┌──────────┐     POST /predict/     ┌──────────────┐     save()     ┌─────────┐
│  Browser  │ ──────────────────────>│  Django View  │ ─────────────>│  MySQL   │
│  (JS)     │    FormData + image    │  predict()    │  XRayImage    │  DB      │
└──────────┘                        └──────┬───────┘               └─────────┘
                                           │                            │
                                           │  image file                │
                                           ▼                            │
                                    ┌──────────────┐                    │
                                    │  media/       │<───── file path ──┘
                                    │  xray_images/ │   stored in DB record
                                    └──────────────┘
```

1. The user drags or selects a chest X-ray image on the frontend
2. JavaScript sends the image as `FormData` to `/predict/` via `fetch`
3. Django's `predict` view receives the file and creates an `XRayImage` record in MySQL
4. The image file is saved to `media/xray_images/`; the file path is stored in the database
5. *(When ML model is enabled)* The image is preprocessed to 150x150 grayscale, normalized, and fed to the model for TB classification

### Database Schema

| Column        | Type         | Description                       |
|---------------|--------------|-----------------------------------|
| `id`          | BIGINT (PK)  | Auto-incrementing primary key     |
| `image`       | VARCHAR(100) | Path to uploaded image file       |
| `uploaded_at` | DATETIME     | Timestamp of upload (auto-set)    |

---

## Screenshots

> Upload your screenshots here after running the project.

| Upload Screen | Analysis Result |
|:---:|:---:|
| *Drag & drop or click to upload* | *TB Detected / Normal with confidence* |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m "Add your feature"`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
