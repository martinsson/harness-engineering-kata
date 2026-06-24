from datetime import datetime

from src.warehouse.inventory import Inventory
from src.warehouse.ledger import Ledger
from src.warehouse.reservations import ReservationService
from src.warehouse.sales import SalesDesk

LOW_STOCK_THRESHOLD = 5
STARTING_CASH = 300.0


class WarehouseDeskApp:
    def __init__(self, clock=None):
        self._clock = clock or datetime.now
        self._inventory = Inventory()
        self._ledger = Ledger()
        self._sales = SalesDesk(self._inventory, self._ledger)
        self._reservations = ReservationService(self._inventory, self._ledger, lambda: self._clock())

    @property
    def _stock(self):
        return self._inventory.stock

    @property
    def _reserved(self):
        return self._inventory.reserved_levels

    @property
    def _cash_balance(self):
        return self._ledger.cash

    @property
    def _event_log(self):
        return self._ledger.events

    def seed_data(self):
        self._inventory.seed(
            {"PEN-BLACK": 40, "PEN-BLUE": 25, "NOTE-A5": 15, "STAPLER": 4},
            {"PEN-BLACK": 0, "PEN-BLUE": 0, "NOTE-A5": 0, "STAPLER": 0},
            {"PEN-BLACK": 1.5, "PEN-BLUE": 1.6, "NOTE-A5": 4.0, "STAPLER": 12.0},
        )
        self._ledger.set_cash(STARTING_CASH)

    def run_demo_day(self):
        commands = [
            "RECV;NOTE-A5;5;2.20",
            "SELL;alice;PEN-BLACK;10",
            "SELL;bob;STAPLER;5",
            "CANCEL;O1002",
            "COUNT;STAPLER",
            "SELL;carol;STAPLER;2",
            "SELL;dan;NOTE-A5;14",
            "COUNT;NOTE-A5",
            "DUMP",
        ]
        for command in commands:
            self.process_line(command)
        self.print_end_of_day_report()

    def process_line(self, line: str):
        parts = line.split(";")
        dispatch = {
            "RECV": self._sales.receive,
            "SELL": self._sales.sell,
            "CANCEL": self._sales.cancel,
            "COUNT": self._handle_count,
            "DUMP": self._handle_dump,
            "RESERVE": self._reservations.reserve,
            "CONFIRM": self._reservations.confirm,
            "RELEASE": self._reservations.release,
        }
        handler = dispatch.get(parts[0])
        if handler:
            handler(parts)
        else:
            self._ledger.record(f"unknown command: {line}")

    def _handle_count(self, parts):
        sku = parts[1]
        self._reservations.purge()
        on_hand = self._inventory.on_hand(sku)
        reserved = self._inventory.reserved(sku)
        available = on_hand - reserved
        self._ledger.record(f"count {sku} onHand={on_hand} reserved={reserved} available={available}")

    def _handle_dump(self, _parts):
        print("---- dump ----")
        print(f"stock={self._stock}")
        print(f"reserved={self._reserved}")
        print(f"orders={self._sales.statuses()}")
        print(f"cashBalance={self._cash_balance}")

    def _print_events(self):
        print()
        print("events:")
        for event in self._event_log:
            print(f" - {event}")

    def print_end_of_day_report(self):
        statuses = list(self._sales.statuses().values())
        shipped = sum(1 for s in statuses if s == "SHIPPED")
        backorder = sum(1 for s in statuses if s == "BACKORDER")
        cancelled = sum(1 for s in statuses if s.startswith("CANCELLED"))
        low_stock = [sku for sku, qty in self._stock.items() if qty < LOW_STOCK_THRESHOLD]
        print()
        print("==== end of day ====")
        print(f"orders shipped: {shipped}")
        print(f"orders backordered: {backorder}")
        print(f"orders cancelled: {cancelled}")
        print(f"cash balance: {self._cash_balance:.2f}")
        print(f"low stock skus: {low_stock}")
        self._print_events()
