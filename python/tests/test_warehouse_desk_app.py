from datetime import datetime
from src.warehouse.warehouse_desk_app import WarehouseDeskApp


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_app() -> WarehouseDeskApp:
    app = WarehouseDeskApp()
    app.seed_data()
    return app


def last_event(app: WarehouseDeskApp) -> str:
    return app._event_log[-1]


# ---------------------------------------------------------------------------
# Characterisation tests for existing commands
# ---------------------------------------------------------------------------

class TestRecv:
    def test_recv_adds_stock(self):
        app = make_app()
        app.process_line("RECV;PEN-BLACK;10;1.00")
        assert app._stock["PEN-BLACK"] == 50

    def test_recv_debits_cash(self):
        app = make_app()
        app.process_line("RECV;PEN-BLACK;10;1.00")
        assert app._cash_balance == 290.0

    def test_recv_logs_event(self):
        app = make_app()
        app.process_line("RECV;PEN-BLACK;10;1.00")
        assert "received 10 of PEN-BLACK at 1.0" in last_event(app)


class TestSell:
    def test_sell_ships_when_stock_available(self):
        app = make_app()
        app.process_line("SELL;alice;PEN-BLACK;10")
        assert app._stock["PEN-BLACK"] == 30

    def test_sell_credits_cash(self):
        app = make_app()
        app.process_line("SELL;alice;PEN-BLACK;10")
        assert app._cash_balance == 315.0

    def test_sell_logs_shipped_event(self):
        app = make_app()
        app.process_line("SELL;alice;PEN-BLACK;10")
        assert "shipped" in last_event(app)

    def test_sell_backordered_when_insufficient_stock(self):
        app = make_app()
        app.process_line("SELL;bob;STAPLER;5")
        assert "backordered" in last_event(app)

    def test_sell_backorder_does_not_change_stock(self):
        app = make_app()
        app.process_line("SELL;bob;STAPLER;5")
        assert app._stock["STAPLER"] == 4

    def test_sell_backorder_does_not_change_cash(self):
        app = make_app()
        app.process_line("SELL;bob;STAPLER;5")
        assert app._cash_balance == 300.0


class TestCancel:
    def test_cancel_backorder_logs_cancelled(self):
        app = make_app()
        app.process_line("SELL;bob;STAPLER;5")
        order_id = "O1001"
        app.process_line(f"CANCEL;{order_id}")
        assert "cancelled backorder" in last_event(app)

    def test_cancel_shipped_restores_stock(self):
        app = make_app()
        app.process_line("SELL;alice;PEN-BLACK;10")
        app.process_line("CANCEL;O1001")
        assert app._stock["PEN-BLACK"] == 40

    def test_cancel_shipped_debits_cash(self):
        app = make_app()
        app.process_line("SELL;alice;PEN-BLACK;10")
        app.process_line("CANCEL;O1001")
        assert app._cash_balance == 300.0

    def test_cancel_nonexistent_logs_error(self):
        app = make_app()
        app.process_line("CANCEL;O9999")
        assert "does not exist" in last_event(app)


class TestCount:
    def test_count_logs_on_hand_and_available(self):
        app = make_app()
        app.process_line("COUNT;STAPLER")
        assert "onHand=4" in last_event(app)
        assert "available=4" in last_event(app)


# ---------------------------------------------------------------------------
# Tests for RESERVE / CONFIRM / RELEASE / expiry
# ---------------------------------------------------------------------------

class TestReserve:
    def test_reserve_reduces_available_stock(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        app.process_line("COUNT;PEN-BLACK")
        assert "available=35" in last_event(app)

    def test_reserve_does_not_reduce_on_hand(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        assert app._stock["PEN-BLACK"] == 40

    def test_reserve_returns_reservation_id_in_event(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        assert "R" in last_event(app)

    def test_reserve_fails_when_insufficient_available(self):
        app = make_app()
        app.process_line("RESERVE;alice;STAPLER;10;30")
        assert "insufficient" in last_event(app)

    def test_reserve_fails_does_not_change_reserved(self):
        app = make_app()
        app.process_line("RESERVE;alice;STAPLER;10;30")
        assert app._reserved.get("STAPLER", 0) == 0

    def test_reserve_accounts_for_existing_reservations(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;38;30")
        app.process_line("RESERVE;bob;PEN-BLACK;5;30")
        assert "insufficient" in last_event(app)


class TestConfirm:
    def test_confirm_ships_order_and_decrements_stock(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"CONFIRM;{reservation_id}")
        assert app._stock["PEN-BLACK"] == 35

    def test_confirm_credits_cash(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"CONFIRM;{reservation_id}")
        assert app._cash_balance == 307.5

    def test_confirm_releases_reserved_qty(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"CONFIRM;{reservation_id}")
        assert app._reserved["PEN-BLACK"] == 0

    def test_confirm_logs_shipped_event(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"CONFIRM;{reservation_id}")
        assert "confirmed" in last_event(app)

    def test_confirm_nonexistent_logs_error(self):
        app = make_app()
        app.process_line("CONFIRM;R9999")
        assert "not found" in last_event(app)

    def test_confirm_expired_reservation_logs_error(self):
        app = WarehouseDeskApp(clock=lambda: datetime(2026, 1, 1, 12, 0, 0))
        app.seed_data()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app._clock = lambda: datetime(2026, 1, 1, 12, 31, 0)
        app.process_line(f"CONFIRM;{reservation_id}")
        assert "expired" in last_event(app)


class TestRelease:
    def test_release_frees_reserved_stock(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"RELEASE;{reservation_id}")
        assert app._reserved["PEN-BLACK"] == 0

    def test_release_logs_event(self):
        app = make_app()
        app.process_line("RESERVE;alice;PEN-BLACK;5;30")
        reservation_id = _extract_reservation_id(last_event(app))
        app.process_line(f"RELEASE;{reservation_id}")
        assert "released" in last_event(app)

    def test_release_nonexistent_logs_error(self):
        app = make_app()
        app.process_line("RELEASE;R9999")
        assert "not found" in last_event(app)


class TestExpiry:
    def test_expired_reservation_frees_stock_on_next_reserve(self):
        app = WarehouseDeskApp(clock=lambda: datetime(2026, 1, 1, 12, 0, 0))
        app.seed_data()
        app.process_line("RESERVE;alice;PEN-BLACK;40;1")
        app._clock = lambda: datetime(2026, 1, 1, 12, 2, 0)
        app.process_line("RESERVE;bob;PEN-BLACK;40;30")
        assert "insufficient" not in last_event(app)

    def test_expired_reservation_frees_stock_on_count(self):
        app = WarehouseDeskApp(clock=lambda: datetime(2026, 1, 1, 12, 0, 0))
        app.seed_data()
        app.process_line("RESERVE;alice;PEN-BLACK;5;1")
        app._clock = lambda: datetime(2026, 1, 1, 12, 2, 0)
        app.process_line("COUNT;PEN-BLACK")
        assert "available=40" in last_event(app)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _extract_reservation_id(event: str) -> str:
    for part in event.split():
        if part.startswith("reservation="):
            return part.split("=", 1)[1]
    raise ValueError(f"No reservation ID found in: {event}")
