using System;
using System.Collections.Generic;
using System.Linq;

namespace Warehouse_Desktop
{
    public class WarehouseDeskApp
    {
        public record SeedItem(string Sku, double Price, int Stock);

        private readonly Dictionary<string, int> stockBySku = new Dictionary<string, int>();
        private readonly Dictionary<string, int> reservedBySku = new Dictionary<string, int>();
        private readonly Dictionary<string, double> priceBySku = new Dictionary<string, double>();
        private readonly Dictionary<string, string> orderStatus = new Dictionary<string, string>();
        private readonly Dictionary<string, string> orderSku = new Dictionary<string, string>();
        private readonly Dictionary<string, int> orderQty = new Dictionary<string, int>();
        private readonly List<string> eventLog = new List<string>();
        private double cashBalance;
        private int nextOrderNumber;

        public void SeedData(IEnumerable<SeedItem> items, double startingCash, int startingOrderNumber)
        {
            stockBySku.Clear();
            reservedBySku.Clear();
            priceBySku.Clear();
            orderStatus.Clear();
            orderSku.Clear();
            orderQty.Clear();
            eventLog.Clear();

            HashSet<string> seenSkus = new HashSet<string>();
            foreach (SeedItem item in items)
            {
                if (item == null)
                {
                    throw new ArgumentException("seed item cannot be null");
                }

                string sku = item.Sku.Trim();
                if (sku.Length == 0)
                {
                    throw new ArgumentException("sku cannot be blank");
                }
                if (item.Price < 0)
                {
                    throw new ArgumentException("price cannot be negative for " + sku);
                }
                if (item.Stock < 0)
                {
                    throw new ArgumentException("stock cannot be negative for " + sku);
                }
                if (!seenSkus.Add(sku))
                {
                    throw new ArgumentException("duplicate sku in seed data: " + sku);
                }

                stockBySku[sku] = item.Stock;
                priceBySku[sku] = item.Price;
                reservedBySku[sku] = 0;
            }

            cashBalance = startingCash;
            nextOrderNumber = startingOrderNumber;
        }

        public void Process(IEnumerable<string> commands)
        {
            foreach (string command in commands)
            {
                ProcessLine(command);
            }
        }

        private void ProcessLine(string line)
        {
            string[] parts = line.Split(';');
            string type = parts[0];

            if ("RECV".Equals(type))
            {
                string sku = parts[1];
                int qty = ParseInt(parts[2]);
                double unitCost = ParseDouble(parts[3]);
                int current = stockBySku.GetValueOrDefault(sku, 0);
                stockBySku[sku] = current + qty;
                cashBalance = cashBalance - (qty * unitCost);
                eventLog.Add("received " + qty + " of " + sku + " at " + unitCost);
                return;
            }

            if ("SELL".Equals(type))
            {
                string customer = parts[1];
                string sku = parts[2];
                int qty = ParseInt(parts[3]);
                string orderId = "O" + nextOrderNumber;
                nextOrderNumber = nextOrderNumber + 1;
                orderSku[orderId] = sku;
                orderQty[orderId] = qty;

                int onHand = stockBySku.GetValueOrDefault(sku, 0);
                int reserved = reservedBySku.GetValueOrDefault(sku, 0);
                int available = onHand - reserved;
                if (available < qty)
                {
                    orderStatus[orderId] = "BACKORDER";
                    eventLog.Add("order " + orderId + " backordered for " + customer + " sku=" + sku + " qty=" + qty);
                }
                else
                {
                    stockBySku[sku] = onHand - qty;
                    double unitPrice = priceBySku.GetValueOrDefault(sku, 0.0);
                    double orderTotal = unitPrice * qty;
                    cashBalance = cashBalance + orderTotal;
                    orderStatus[orderId] = "SHIPPED";
                    eventLog.Add("order " + orderId + " shipped to " + customer + " amount=" + orderTotal);
                }
                return;
            }

            if ("CANCEL".Equals(type))
            {
                string orderId = parts[1];
                if (!orderStatus.TryGetValue(orderId, out string? status))
                {
                    eventLog.Add("cannot cancel " + orderId + " because it does not exist");
                    return;
                }

                if ("BACKORDER".Equals(status))
                {
                    orderStatus[orderId] = "CANCELLED";
                    eventLog.Add("cancelled backorder " + orderId);
                    return;
                }

                if ("SHIPPED".Equals(status))
                {
                    string sku = orderSku[orderId];
                    int qty = orderQty.GetValueOrDefault(orderId, 0);
                    int current = stockBySku.GetValueOrDefault(sku, 0);
                    stockBySku[sku] = current + qty;
                    double unitPrice = priceBySku.GetValueOrDefault(sku, 0.0);
                    cashBalance = cashBalance - (unitPrice * qty);
                    orderStatus[orderId] = "CANCELLED_AFTER_SHIP";
                    eventLog.Add("cancelled shipped order " + orderId + " with restock");
                    return;
                }

                eventLog.Add("order " + orderId + " could not be cancelled from state " + status);
                return;
            }

            if ("COUNT".Equals(type))
            {
                string sku = parts[1];
                int onHand = stockBySku.GetValueOrDefault(sku, 0);
                int reserved = reservedBySku.GetValueOrDefault(sku, 0);
                int available = onHand - reserved;
                eventLog.Add("count " + sku + " onHand=" + onHand + " reserved=" + reserved + " available=" + available);
                return;
            }

            if ("DUMP".Equals(type))
            {
                Console.WriteLine("---- dump ----");
                Console.WriteLine("stock={" + string.Join(", ", stockBySku.Select(kvp => kvp.Key + "=" + kvp.Value)) + "}");
                Console.WriteLine("reserved={" + string.Join(", ", reservedBySku.Select(kvp => kvp.Key + "=" + kvp.Value)) + "}");
                Console.WriteLine("orders={" + string.Join(", ", orderStatus.Select(kvp => kvp.Key + "=" + kvp.Value)) + "}");
                Console.WriteLine("cashBalance=" + cashBalance);
                return;
            }

            eventLog.Add("unknown command: " + line);
        }

        private int ParseInt(string value)
        {
            return int.Parse(value.Trim());
        }

        private double ParseDouble(string value)
        {
            return double.Parse(value.Trim(), System.Globalization.CultureInfo.InvariantCulture);
        }

        public void PrintEndOfDayReport()
        {
            int shipped = 0;
            int backorder = 0;
            int cancelled = 0;
            foreach (string status in orderStatus.Values)
            {
                if ("SHIPPED".Equals(status))
                {
                    shipped = shipped + 1;
                }
                else if ("BACKORDER".Equals(status))
                {
                    backorder = backorder + 1;
                }
                else if (status.StartsWith("CANCELLED"))
                {
                    cancelled = cancelled + 1;
                }
            }

            List<string> lowStock = new List<string>();
            foreach (KeyValuePair<string, int> item in stockBySku)
            {
                if (item.Value < 5)
                {
                    lowStock.Add(item.Key);
                }
            }

            Console.WriteLine();
            Console.WriteLine("==== end of day ====");
            Console.WriteLine("orders shipped: " + shipped);
            Console.WriteLine("orders backordered: " + backorder);
            Console.WriteLine("orders cancelled: " + cancelled);
            Console.WriteLine("cash balance: " + string.Format("{0:F2}", cashBalance));
            Console.WriteLine("low stock skus: [" + string.Join(", ", lowStock) + "]");
            Console.WriteLine();
            Console.WriteLine("events:");
            foreach (string @event in eventLog)
            {
                Console.WriteLine(" - " + @event);
            }
        }
    }
}
