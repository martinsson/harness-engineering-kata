export interface SeedItem {
    sku: string;
    price: number;
    stock: number;
}

export class WarehouseDeskApp {
    private stockBySku: Map<string, number> = new Map();
    private reservedBySku: Map<string, number> = new Map();
    private priceBySku: Map<string, number> = new Map();
    private orderStatus: Map<string, string> = new Map();
    private orderSku: Map<string, string> = new Map();
    private orderQty: Map<string, number> = new Map();
    private eventLog: string[] = [];
    private cashBalance: number = 0;
    private nextOrderNumber: number = 0;

    public seedData(items: SeedItem[], startingCash: number, startingOrderNumber: number): void {
        this.stockBySku.clear();
        this.reservedBySku.clear();
        this.priceBySku.clear();
        this.orderStatus.clear();
        this.orderSku.clear();
        this.orderQty.clear();
        this.eventLog = [];

        const seenSkus: Set<string> = new Set();
        for (const item of items) {
            if (item === null || item === undefined) {
                throw new Error("seed item cannot be null");
            }
            const sku = item.sku.trim();
            if (sku === "") {
                throw new Error("sku cannot be blank");
            }
            if (item.price < 0) {
                throw new Error("price cannot be negative for " + sku);
            }
            if (item.stock < 0) {
                throw new Error("stock cannot be negative for " + sku);
            }
            if (seenSkus.has(sku)) {
                throw new Error("duplicate sku in seed data: " + sku);
            }
            seenSkus.add(sku);

            this.stockBySku.set(sku, item.stock);
            this.priceBySku.set(sku, item.price);
            this.reservedBySku.set(sku, 0);
        }

        this.cashBalance = startingCash;
        this.nextOrderNumber = startingOrderNumber;
    }

    public process(commands: string[]): void {
        for (const command of commands) {
            this.processLine(command);
        }
    }

    private processLine(line: string): void {
        const parts = line.split(";");
        const type = parts[0];

        if (type === "RECV") {
            const sku = parts[1];
            const qty = this.parseInt(parts[2]);
            const unitCost = this.parseDouble(parts[3]);
            const current = this.stockBySku.get(sku) || 0;
            this.stockBySku.set(sku, current + qty);
            this.cashBalance = this.cashBalance - (qty * unitCost);
            this.eventLog.push(`received ${qty} of ${sku} at ${this.formatDouble(unitCost)}`);
            return;
        }

        if (type === "SELL") {
            const customer = parts[1];
            const sku = parts[2];
            const qty = this.parseInt(parts[3]);
            const orderId = "O" + this.nextOrderNumber;
            this.nextOrderNumber = this.nextOrderNumber + 1;
            this.orderSku.set(orderId, sku);
            this.orderQty.set(orderId, qty);

            const onHand = this.stockBySku.get(sku) || 0;
            const reserved = this.reservedBySku.get(sku) || 0;
            const available = onHand - reserved;
            if (available < qty) {
                this.orderStatus.set(orderId, "BACKORDER");
                this.eventLog.push(`order ${orderId} backordered for ${customer} sku=${sku} qty=${qty}`);
            } else {
                this.stockBySku.set(sku, onHand - qty);
                const unitPrice = this.priceBySku.get(sku) || 0.0;
                const orderTotal = unitPrice * qty;
                this.cashBalance = this.cashBalance + orderTotal;
                this.orderStatus.set(orderId, "SHIPPED");
                this.eventLog.push(`order ${orderId} shipped to ${customer} amount=${this.formatDouble(orderTotal)}`);
            }
            return;
        }

        if (type === "CANCEL") {
            const orderId = parts[1];
            const status = this.orderStatus.get(orderId);
            if (status === undefined) {
                this.eventLog.push(`cannot cancel ${orderId} because it does not exist`);
                return;
            }

            if (status === "BACKORDER") {
                this.orderStatus.set(orderId, "CANCELLED");
                this.eventLog.push(`cancelled backorder ${orderId}`);
                return;
            }

            if (status === "SHIPPED") {
                const sku = this.orderSku.get(orderId)!;
                const qty = this.orderQty.get(orderId) || 0;
                const current = this.stockBySku.get(sku) || 0;
                this.stockBySku.set(sku, current + qty);
                const unitPrice = this.priceBySku.get(sku) || 0.0;
                this.cashBalance = this.cashBalance - (unitPrice * qty);
                this.orderStatus.set(orderId, "CANCELLED_AFTER_SHIP");
                this.eventLog.push(`cancelled shipped order ${orderId} with restock`);
                return;
            }

            this.eventLog.push(`order ${orderId} could not be cancelled from state ${status}`);
            return;
        }

        if (type === "COUNT") {
            const sku = parts[1];
            const onHand = this.stockBySku.get(sku) || 0;
            const reserved = this.reservedBySku.get(sku) || 0;
            const available = onHand - reserved;
            this.eventLog.push(`count ${sku} onHand=${onHand} reserved=${reserved} available=${available}`);
            return;
        }

        if (type === "DUMP") {
            console.log("---- dump ----");
            console.log("stock=", this.mapToString(this.stockBySku));
            console.log("reserved=", this.mapToString(this.reservedBySku));
            console.log("orders=", this.mapToString(this.orderStatus));
            console.log("cashBalance=", this.cashBalance);
            return;
        }

        this.eventLog.push(`unknown command: ${line}`);
    }

    private parseInt(value: string): number {
        return parseInt(value.trim(), 10);
    }

    private parseDouble(value: string): number {
        return parseFloat(value.trim());
    }

    private formatDouble(value: number): string {
        const s = value.toString();
        return s.includes('.') ? s : s + '.0';
    }

    private mapToString(map: Map<string, any>): string {
        const obj: { [key: string]: any } = {};
        map.forEach((value, key) => {
            obj[key] = value;
        });
        return JSON.stringify(obj);
    }

    public printEndOfDayReport(): void {
        let shipped = 0;
        let backorder = 0;
        let cancelled = 0;

        this.orderStatus.forEach(status => {
            if (status === "SHIPPED") {
                shipped = shipped + 1;
            } else if (status === "BACKORDER") {
                backorder = backorder + 1;
            } else if (status.startsWith("CANCELLED")) {
                cancelled = cancelled + 1;
            }
        });

        const lowStock: string[] = [];
        this.stockBySku.forEach((value, key) => {
            if (value < 5) {
                lowStock.push(key);
            }
        });

        console.log();
        console.log("==== end of day ====");
        console.log(`orders shipped: ${shipped}`);
        console.log(`orders backordered: ${backorder}`);
        console.log(`orders cancelled: ${cancelled}`);
        console.log(`cash balance: ${this.cashBalance.toFixed(2)}`);
        console.log(`low stock skus: [${lowStock.join(", ")}]`);
        console.log();
        console.log("events:");
        for (const event of this.eventLog) {
            console.log(` - ${event}`);
        }
    }
}
