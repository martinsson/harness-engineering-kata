class OrderBook:
    """Stores order status plus the SKU and quantity behind each order."""

    def __init__(self):
        self._status: dict[str, str] = {}
        self._sku: dict[str, str] = {}
        self._qty: dict[str, int] = {}
        self._next_number: int = 1001

    def open(self, sku, qty, status):
        order_id = f"O{self._next_number}"
        self._next_number += 1
        self._sku[order_id] = sku
        self._qty[order_id] = qty
        self._status[order_id] = status
        return order_id

    def status(self, order_id):
        return self._status.get(order_id)

    def set_status(self, order_id, status):
        self._status[order_id] = status

    def sku(self, order_id):
        return self._sku[order_id]

    def qty(self, order_id):
        return self._qty.get(order_id, 0)

    def statuses(self):
        return self._status
