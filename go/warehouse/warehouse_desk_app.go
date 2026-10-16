package warehouse

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
)

type SeedItem struct {
	Sku   string
	Price float64
	Stock int
}

type WarehouseDeskApp struct {
	stockBySku      map[string]int
	reservedBySku   map[string]int
	priceBySku      map[string]float64
	orderStatus     map[string]string
	orderSku        map[string]string
	orderQty        map[string]int
	eventLog        []string
	cashBalance     float64
	nextOrderNumber int
}

func NewWarehouseDeskApp() *WarehouseDeskApp {
	return &WarehouseDeskApp{
		stockBySku:    make(map[string]int),
		reservedBySku: make(map[string]int),
		priceBySku:    make(map[string]float64),
		orderStatus:   make(map[string]string),
		orderSku:      make(map[string]string),
		orderQty:      make(map[string]int),
		eventLog:      []string{},
	}
}

func (app *WarehouseDeskApp) SeedData(items []SeedItem, startingCash float64, startingOrderNumber int) {
	app.stockBySku = make(map[string]int)
	app.reservedBySku = make(map[string]int)
	app.priceBySku = make(map[string]float64)
	app.orderStatus = make(map[string]string)
	app.orderSku = make(map[string]string)
	app.orderQty = make(map[string]int)
	app.eventLog = []string{}

	seenSkus := make(map[string]bool)
	for _, item := range items {
		sku := strings.TrimSpace(item.Sku)
		if sku == "" {
			panic("sku cannot be blank")
		}
		if item.Price < 0 {
			panic("price cannot be negative for " + sku)
		}
		if item.Stock < 0 {
			panic("stock cannot be negative for " + sku)
		}
		if seenSkus[sku] {
			panic("duplicate sku in seed data: " + sku)
		}

		seenSkus[sku] = true
		app.stockBySku[sku] = item.Stock
		app.priceBySku[sku] = item.Price
		app.reservedBySku[sku] = 0
	}

	app.cashBalance = startingCash
	app.nextOrderNumber = startingOrderNumber
}

func (app *WarehouseDeskApp) Process(commands []string) {
	for _, command := range commands {
		app.processLine(command)
	}
}

func (app *WarehouseDeskApp) processLine(line string) {
	parts := strings.Split(line, ";")
	cmd := parts[0]

	if cmd == "RECV" {
		sku := parts[1]
		qty := parseInt(parts[2])
		unitCost := parseFloat(parts[3])
		app.stockBySku[sku] += qty
		app.cashBalance -= float64(qty) * unitCost
		app.eventLog = append(app.eventLog, fmt.Sprintf("received %d of %s at %s", qty, sku, formatFloat(unitCost)))
		return
	}

	if cmd == "SELL" {
		customer := parts[1]
		sku := parts[2]
		qty := parseInt(parts[3])
		orderId := "O" + strconv.Itoa(app.nextOrderNumber)
		app.nextOrderNumber++
		app.orderSku[orderId] = sku
		app.orderQty[orderId] = qty

		onHand := app.stockBySku[sku]
		reserved := app.reservedBySku[sku]
		available := onHand - reserved
		if available < qty {
			app.orderStatus[orderId] = "BACKORDER"
			app.eventLog = append(app.eventLog, fmt.Sprintf("order %s backordered for %s sku=%s qty=%d", orderId, customer, sku, qty))
		} else {
			app.stockBySku[sku] = onHand - qty
			orderTotal := app.priceBySku[sku] * float64(qty)
			app.cashBalance += orderTotal
			app.orderStatus[orderId] = "SHIPPED"
			app.eventLog = append(app.eventLog, fmt.Sprintf("order %s shipped to %s amount=%s", orderId, customer, formatFloat(orderTotal)))
		}
		return
	}

	if cmd == "CANCEL" {
		orderId := parts[1]
		status, exists := app.orderStatus[orderId]
		if !exists {
			app.eventLog = append(app.eventLog, fmt.Sprintf("cannot cancel %s because it does not exist", orderId))
			return
		}

		if status == "BACKORDER" {
			app.orderStatus[orderId] = "CANCELLED"
			app.eventLog = append(app.eventLog, fmt.Sprintf("cancelled backorder %s", orderId))
			return
		}

		if status == "SHIPPED" {
			sku := app.orderSku[orderId]
			qty := app.orderQty[orderId]
			app.stockBySku[sku] += qty
			app.cashBalance -= app.priceBySku[sku] * float64(qty)
			app.orderStatus[orderId] = "CANCELLED_AFTER_SHIP"
			app.eventLog = append(app.eventLog, fmt.Sprintf("cancelled shipped order %s with restock", orderId))
			return
		}

		app.eventLog = append(app.eventLog, fmt.Sprintf("order %s could not be cancelled from state %s", orderId, status))
		return
	}

	if cmd == "COUNT" {
		sku := parts[1]
		onHand := app.stockBySku[sku]
		reserved := app.reservedBySku[sku]
		available := onHand - reserved
		app.eventLog = append(app.eventLog, fmt.Sprintf("count %s onHand=%d reserved=%d available=%d", sku, onHand, reserved, available))
		return
	}

	if cmd == "DUMP" {
		fmt.Println("---- dump ----")
		fmt.Printf("stock=%s\n", formatIntMap(app.stockBySku))
		fmt.Printf("reserved=%s\n", formatIntMap(app.reservedBySku))
		fmt.Printf("orders=%s\n", formatStringMap(app.orderStatus))
		fmt.Printf("cashBalance=%s\n", formatFloat(app.cashBalance))
		return
	}

	app.eventLog = append(app.eventLog, "unknown command: "+line)
}

func parseInt(value string) int {
	v, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil {
		panic(err)
	}
	return v
}

func parseFloat(value string) float64 {
	v, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
	if err != nil {
		panic(err)
	}
	return v
}

func formatFloat(v float64) string {
	s := strconv.FormatFloat(v, 'f', -1, 64)
	if !strings.Contains(s, ".") {
		s += ".0"
	}
	return s
}

func formatIntMap(m map[string]int) string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, k := range keys {
		parts = append(parts, fmt.Sprintf("%s=%d", k, m[k]))
	}
	return "{" + strings.Join(parts, ", ") + "}"
}

func formatStringMap(m map[string]string) string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, k := range keys {
		parts = append(parts, fmt.Sprintf("%s=%s", k, m[k]))
	}
	return "{" + strings.Join(parts, ", ") + "}"
}

func (app *WarehouseDeskApp) PrintEndOfDayReport() {
	shipped := 0
	backorder := 0
	cancelled := 0
	for _, status := range app.orderStatus {
		if status == "SHIPPED" {
			shipped++
		} else if status == "BACKORDER" {
			backorder++
		} else if strings.HasPrefix(status, "CANCELLED") {
			cancelled++
		}
	}

	lowStock := []string{}
	for sku, qty := range app.stockBySku {
		if qty < 5 {
			lowStock = append(lowStock, sku)
		}
	}
	sort.Strings(lowStock)

	fmt.Println()
	fmt.Println("==== end of day ====")
	fmt.Printf("orders shipped: %d\n", shipped)
	fmt.Printf("orders backordered: %d\n", backorder)
	fmt.Printf("orders cancelled: %d\n", cancelled)
	fmt.Printf("cash balance: %.2f\n", app.cashBalance)
	fmt.Printf("low stock skus: [%s]\n", strings.Join(lowStock, ", "))
	fmt.Println()
	fmt.Println("events:")
	for _, event := range app.eventLog {
		fmt.Printf(" - %s\n", event)
	}
}

