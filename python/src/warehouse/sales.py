from src.warehouse.order_book import OrderBook


class SalesDesk:
    """Handles receiving, selling, and cancelling orders."""

    def __init__(self, inventory, ledger):
        self._inventory = inventory
        self._ledger = ledger
        self._orders = OrderBook()

    def statuses(self):
        return self._orders.statuses()

    def receive(self, parts):
        sku, qty, unit_cost = parts[1], int(parts[2].strip()), float(parts[3].strip())
        self._inventory.receive(sku, qty)
        self._ledger.debit(qty * unit_cost)
        self._ledger.record(f"received {qty} of {sku} at {unit_cost}")

    def sell(self, parts):
        customer, sku, qty = parts[1], parts[2], int(parts[3].strip())
        if self._inventory.available(sku) < qty:
            order_id = self._orders.open(sku, qty, "BACKORDER")
            self._ledger.record(f"order {order_id} backordered for {customer} sku={sku} qty={qty}")
            return
        order_id = self._orders.open(sku, qty, "SHIPPED")
        order_total = self._inventory.price(sku) * qty
        self._inventory.take(sku, qty)
        self._ledger.credit(order_total)
        self._ledger.record(f"order {order_id} shipped to {customer} amount={order_total}")

    def cancel(self, parts):
        order_id = parts[1]
        status = self._orders.status(order_id)
        if status is None:
            self._ledger.record(f"cannot cancel {order_id} because it does not exist")
            return
        if status == "BACKORDER":
            self._orders.set_status(order_id, "CANCELLED")
            self._ledger.record(f"cancelled backorder {order_id}")
            return
        if status == "SHIPPED":
            self._restock(order_id)
            return
        self._ledger.record(f"order {order_id} could not be cancelled from state {status}")

    def _restock(self, order_id):
        sku = self._orders.sku(order_id)
        qty = self._orders.qty(order_id)
        self._inventory.receive(sku, qty)
        self._ledger.debit(self._inventory.price(sku) * qty)
        self._orders.set_status(order_id, "CANCELLED_AFTER_SHIP")
        self._ledger.record(f"cancelled shipped order {order_id} with restock")
