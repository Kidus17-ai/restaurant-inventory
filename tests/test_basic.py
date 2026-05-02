import pytest
from app import create_app

def test_app_creates_successfully():
    app = create_app()
    assert app is not None

def test_dashboard_loads():
    app = create_app()
    with app.test_client() as client:
        response = client.get('/')
        assert response.status_code == 200