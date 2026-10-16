package main

import (
	"github.com/martinsson/harness-engineering-kata/warehouse"
)

func main() {
	app := warehouse.NewWarehouseDeskApp()
	app.SeedData(
		[]warehouse.SeedItem{
			{Sku: "PEN-BLACK", Price: 1.5, Stock: 40},
			{Sku: "PEN-BLUE", Price: 1.6, Stock: 25},
			{Sku: "NOTE-A5", Price: 4.0, Stock: 15},
			{Sku: "STAPLER", Price: 12.0, Stock: 4},
		},
		300.0,
		1001,
	)

	commands := []string{
		"RECV;NOTE-A5;5;2.20",
		"SELL;alice;PEN-BLACK;10",
		"SELL;bob;STAPLER;5",
		"CANCEL;O1002",
		"COUNT;STAPLER",
		"SELL;carol;STAPLER;2",
		"SELL;dan;NOTE-A5;14",
		"COUNT;NOTE-A5",
		"DUMP",
	}

	app.Process(commands)
	app.PrintEndOfDayReport()
}
