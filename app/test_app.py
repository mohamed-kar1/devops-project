import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home(client):
    r = client.get('/')
    assert r.status_code == 200
    data = r.get_json()
    assert data['status'] == 'running'

def test_health(client):
    r = client.get('/health')
    assert r.status_code == 200
    assert r.get_json()['status'] == 'healthy'

def test_info(client):
    r = client.get('/api/info')
    assert r.status_code == 200
    assert 'app' in r.get_json()
