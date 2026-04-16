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

    public seedData(): void {
        this.stockBySku.set("PEN-BLACK", 40);
        this.stockBySku.set("PEN-BLUE", 25);
        this.stockBySku.set("NOTE-A5", 15);
        this.stockBySku.set("STAPLER", 4);

        this.reservedBySku.set("PEN-BLACK", 0);
        this.reservedBySku.set("PEN-BLUE", 0);
        this.reservedBySku.set("NOTE-A5", 0);
        this.reservedBySku.set("STAPLER", 0);

        this.priceBySku.set("PEN-BLACK", 1.5);
        this.priceBySku.set("PEN-BLUE", 1.6);
        this.priceBySku.set("NOTE-A5", 4.0);
        this.priceBySku.set("STAPLER", 12.0);

        this.cashBalance = 300.0;
        this.nextOrderNumber = 1001;
    }

    public runDemoDay(): void {
        const commands = [
            "RECV;NOTE-A5;5;2.20",
            "SELL;alice;PEN-BLACK;10",
            "SELL;bob;STAPLER;5",
            "CANCEL;O1002",
            "COUNT;STAPLER",
            "SELL;carol;STAPLER;2",
            "SELL;dan;NOTE-A5;14",
            "COUNT;NOTE-A5",
            "DUMP"
        ];

        for (const command of commands) {
            this.processLine(command);
        }
        this.printEndOfDayReport();
    }

    public processLine(line: string): void {
        const parts = line.split(";");
        const type = parts[0];

        if (type === "RECV") {
            const sku = parts[1];
            const qty = this.parseInt(parts[2]);
            const unitCost = this.parseDouble(parts[3]);
            const current = this.stockBySku.get(sku) || 0;
            this.stockBySku.set(sku, current + qty);
            this.cashBalance = this.cashBalance - (qty * unitCost);
            this.eventLog.push(`received ${qty} of ${sku} at ${unitCost}`);
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
                this.eventLog.push(`order ${orderId} shipped to ${customer} amount=${orderTotal}`);
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
                const sku = this.orderSku.get(orderId);
                const qty = this.orderQty.get(orderId) || 0;
                const current = this.stockBySku.get(sku || "") || 0;
                this.stockBySku.set(sku || "", current + qty);
                const unitPrice = this.priceBySku.get(sku || "") || 0.0;
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
        return parseInt(value.trim());
    }

    private parseDouble(value: string): number {
        return parseFloat(value.trim());
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
        console.log("orders shipped:", shipped);
        console.log("orders backordered:", backorder);
        console.log("orders cancelled:", cancelled);
        console.log("cash balance:", this.cashBalance.toFixed(2));
        console.log("low stock skus:", lowStock);
        console.log();
        console.log("events:");
        for (const event of this.eventLog) {
            console.log(" -", event);
        }
    }
}
