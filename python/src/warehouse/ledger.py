class Ledger:
    """Holds the cash balance and the running event log."""

    def __init__(self):
        self._cash: float = 0
        self._events: list[str] = []

    @property
    def cash(self):
        return self._cash

    @property
    def events(self):
        return self._events

    def set_cash(self, amount):
        self._cash = amount

    def credit(self, amount):
        self._cash += amount

    def debit(self, amount):
        self._cash -= amount

    def record(self, message):
        self._events.append(message)
