from collections.abc import Iterable
from dataclasses import dataclass


@dataclass(frozen=True)
class SeedItem:
    sku: str
    price: float
    stock: int


class WarehouseDeskApp:
    def __init__(self):
        self._stock: dict[str, int] = {}
        self._reserved: dict[str, int] = {}
        self._price: dict[str, float] = {}
        self._order_status: dict[str, str] = {}
        self._order_sku: dict[str, str] = {}
        self._order_qty: dict[str, int] = {}
        self._event_log: list[str] = []
        self._cash_balance: float = 0.0
        self._next_order_number: int = 1001

    def seed_data(
        self,
        items: Iterable[SeedItem],
        starting_cash: float,
        starting_order_number: int,
    ):
        self._stock.clear()
        self._reserved.clear()
        self._price.clear()
        self._order_status.clear()
        self._order_sku.clear()
        self._order_qty.clear()
        self._event_log.clear()

        seen_skus: set[str] = set()
        for item in items:
            if item is None:
                raise ValueError("seed item cannot be None")

            sku = item.sku.strip()
            if not sku:
                raise ValueError("sku cannot be blank")
            if item.price < 0:
                raise ValueError(f"price cannot be negative for {sku}")
            if item.stock < 0:
                raise ValueError(f"stock cannot be negative for {sku}")
            if sku in seen_skus:
                raise ValueError(f"duplicate sku in seed data: {sku}")

            seen_skus.add(sku)
            self._stock[sku] = item.stock
            self._reserved[sku] = 0
            self._price[sku] = item.price

        self._cash_balance = starting_cash
        self._next_order_number = starting_order_number

    def process(self, commands: Iterable[str]):
        for command in commands:
            self._process_line(command)

    def _process_line(self, line: str):
        parts = line.split(";")
        cmd = parts[0]

        if cmd == "RECV":
            sku, qty, unit_cost = parts[1], int(parts[2].strip()), float(parts[3].strip())
            self._stock[sku] = self._stock.get(sku, 0) + qty
            self._cash_balance -= qty * unit_cost
            self._event_log.append(f"received {qty} of {sku} at {unit_cost}")
            return

        if cmd == "SELL":
            customer, sku, qty = parts[1], parts[2], int(parts[3].strip())
            order_id = f"O{self._next_order_number}"
            self._next_order_number += 1
            self._order_sku[order_id] = sku
            self._order_qty[order_id] = qty

            on_hand = self._stock.get(sku, 0)
            reserved = self._reserved.get(sku, 0)
            available = on_hand - reserved
            if available < qty:
                self._order_status[order_id] = "BACKORDER"
                self._event_log.append(f"order {order_id} backordered for {customer} sku={sku} qty={qty}")
            else:
                self._stock[sku] = on_hand - qty
                order_total = self._price.get(sku, 0.0) * qty
                self._cash_balance += order_total
                self._order_status[order_id] = "SHIPPED"
                self._event_log.append(f"order {order_id} shipped to {customer} amount={order_total}")
            return

        if cmd == "CANCEL":
            order_id = parts[1]
            status = self._order_status.get(order_id)
            if status is None:
                self._event_log.append(f"cannot cancel {order_id} because it does not exist")
                return
            if status == "BACKORDER":
                self._order_status[order_id] = "CANCELLED"
                self._event_log.append(f"cancelled backorder {order_id}")
                return
            if status == "SHIPPED":
                sku = self._order_sku[order_id]
                qty = self._order_qty.get(order_id, 0)
                self._stock[sku] = self._stock.get(sku, 0) + qty
                self._cash_balance -= self._price.get(sku, 0.0) * qty
                self._order_status[order_id] = "CANCELLED_AFTER_SHIP"
                self._event_log.append(f"cancelled shipped order {order_id} with restock")
                return
            self._event_log.append(f"order {order_id} could not be cancelled from state {status}")
            return

        if cmd == "COUNT":
            sku = parts[1]
            on_hand = self._stock.get(sku, 0)
            reserved = self._reserved.get(sku, 0)
            available = on_hand - reserved
            self._event_log.append(f"count {sku} onHand={on_hand} reserved={reserved} available={available}")
            return

        if cmd == "DUMP":
            print("---- dump ----")
            print(f"stock={self._stock}")
            print(f"reserved={self._reserved}")
            print(f"orders={self._order_status}")
            print(f"cashBalance={self._cash_balance}")
            return

        self._event_log.append(f"unknown command: {line}")

    def print_end_of_day_report(self):
        shipped = sum(1 for s in self._order_status.values() if s == "SHIPPED")
        backorder = sum(1 for s in self._order_status.values() if s == "BACKORDER")
        cancelled = sum(1 for s in self._order_status.values() if s.startswith("CANCELLED"))
        low_stock = [sku for sku, qty in self._stock.items() if qty < 5]

        print()
        print("==== end of day ====")
        print(f"orders shipped: {shipped}")
        print(f"orders backordered: {backorder}")
        print(f"orders cancelled: {cancelled}")
        print(f"cash balance: {self._cash_balance:.2f}")
        print(f"low stock skus: {low_stock}")
        print()
        print("events:")
        for event in self._event_log:
            print(f" - {event}")
