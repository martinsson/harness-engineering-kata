class Inventory:
    """Tracks on-hand stock, reserved holds, and unit prices per SKU."""

    def __init__(self):
        self._stock: dict[str, int] = {}
        self._reserved: dict[str, int] = {}
        self._price: dict[str, float] = {}

    def seed(self, stock, reserved, prices):
        self._stock = stock
        self._reserved = reserved
        self._price = prices

    @property
    def stock(self):
        return self._stock

    @property
    def reserved_levels(self):
        return self._reserved

    def on_hand(self, sku):
        return self._stock.get(sku, 0)

    def reserved(self, sku):
        return self._reserved.get(sku, 0)

    def available(self, sku):
        return self.on_hand(sku) - self.reserved(sku)

    def price(self, sku):
        return self._price.get(sku, 0)

    def receive(self, sku, qty):
        self._stock[sku] = self.on_hand(sku) + qty

    def take(self, sku, qty):
        self._stock[sku] = self.on_hand(sku) - qty

    def hold(self, sku, qty):
        self._reserved[sku] = self.reserved(sku) + qty

    def free(self, sku, qty):
        self._reserved[sku] = max(0, self.reserved(sku) - qty)
