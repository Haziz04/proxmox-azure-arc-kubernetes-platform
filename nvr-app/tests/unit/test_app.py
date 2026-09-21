import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from app import status_payload


def test_status_payload():
    result = status_payload("123", "test")

    assert result["service"] == "tvms-nvr"
    assert result["status"] == "ok"
    assert result["version"] == "123"
    assert result["environment"] == "test"
