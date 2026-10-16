# FreeBASIC Migration Plan - extracted from Vibe journal `unified/5a8084c8-78c9-12c5-0652-a49cad0a09e2/journal`

---

## Task List (revised: compilable after every increment)

Strategy: **add new methods alongside old ones -> switch caller -> remove old methods.** Every increment compiles and runs.

### Increment 0 - Verify baseline (read-only)

- [x] Confirm clean git status, read all 4 `.bas` files, capture baseline output
- **Compiles:** yes (no changes)

### Increment 1 - `dict.bas`: `Clear` + `PrintKeyValues`

- [x] `IntegerDict`: add `Declare Sub Clear()` + impl (`count = 0`)
- [x] `IntegerDict`: rewrite `PrintKeyValues` -> `{k=v, k=v}` (use `Str(values(i))`)
- [x] `DoubleDict`: add `Clear` + rewrite `PrintKeyValues`
- [x] `StringDict`: add `Clear` + rewrite `PrintKeyValues` (values directly, no `Str`)
- **Compiles:** yes - new methods unused, format change only affects DUMP output

### Increment 2 - `list.bas`: `Clear` + `Contains` + `PrintItemsOneLine`

- [x] `StringList`: add `Declare Sub Clear()` + impl (`count = 0`)
- [x] `StringList`: add `Declare Function Contains(item As String) As Integer` + impl (linear scan, 1/0)
- [x] `StringList`: rewrite `PrintItemsOneLine` -> build `[a, b]`, `Print s;` (trailing `;`, no newline)
- [x] `PrintItems` - leave unchanged
- **Compiles:** yes - same reasoning

### Increment 3 - `warehouse.bas`: add `SeedItem` + `FormatDouble` + `FormatFixed2`

- [ ] Add `Type SeedItem` (sku As String, price As Double, stock As Integer) after `#include`s, before `WarehouseDeskApp`
- [ ] Add `FormatDouble(value As Double) As String` - full body (`Str(value)`, append `.0` if no `.`)
- [ ] Add `FormatFixed2(value As Double) As String` - full body (`CLng(value * 100)`, split sign/whole/cents, `Right("0" + Str(cents Mod 100), 2)`)
- [ ] Both in a `private:` section of `WarehouseDeskApp`
- **Compiles:** yes - purely additive, nothing calls them yet

### Increment 4 - `warehouse.bas`: add new `SeedData` + `Process` (keep old ones)

- [ ] Add `Sub SeedData(items() As SeedItem, startingCash As Double, startingOrderNumber As Integer)` - full body with clears + validation (FreeBASIC overloading: coexists with old `SeedData()`)
- [ ] Add `Sub Process(commands() As String)` - full body, loops `ProcessLine`
- [ ] Both in `public:` section
- **Compiles:** yes - old `main.bas` still calls old `SeedData()` + `RunDemoDay()`

### Increment 5 - `warehouse.bas`: make `ProcessLine` + `Split` private

- [ ] Move `Declare Sub ProcessLine` + `Declare Function Split` to `private:` section
- **Compiles:** yes - module-scoped, `RunDemoDay` can still call them

### Increment 6 - `warehouse.bas`: update `ProcessLine` + `PrintEndOfDayReport` formatting

- [ ] `ProcessLine`: RECV/SELL event log uses `FormatDouble`
- [ ] `ProcessLine` DUMP: `PrintKeyValues` calls + `cashBalance=` + `FormatDouble`
- [ ] `PrintEndOfDayReport`: `cash balance:` + `FormatFixed2(cashBalance)`
- [ ] Old `RunDemoDay` still works - output partially updated, not yet canonical
- **Compiles:** yes - `FormatDouble`/`FormatFixed2` bodies exist since Increment 3

### Increment 7 - `main.bas`: switch to new API

- [ ] Build `items(0 To 3) As SeedItem` with 4 canonical items (PEN-BLACK, PEN-BLUE, NOTE-A5, STAPLER)
- [ ] Call `app.SeedData(items(), 300.0, 1001)`
- [ ] Build `commands(0 To 8) As String` with 9 canonical commands
- [ ] Call `app.Process(commands())` + `app.PrintEndOfDayReport()`
- [ ] Remove old `app.SeedData()` + `app.RunDemoDay()` calls
- **Compiles:** yes - **output should now match canonical target exactly**

### Increment 8 - `warehouse.bas`: remove old `SeedData()` + `RunDemoDay`

- [ ] Delete old no-arg `SeedData` and `RunDemoDay` (declarations + bodies)
- [ ] Reorder methods to final canonical order: `SeedData(items,...)`, `Process`, `ProcessLine` (private), `Split` (private), `FormatDouble` (private), `FormatFixed2` (private), `PrintEndOfDayReport`
- **Compiles:** yes - only canonical API remains, `main.bas` uses it

### Increment 9 - CRLF normalize + final verification

- [ ] Normalize all 4 `.bas` files to CRLF, UTF-8 no BOM (PowerShell)
- [ ] Byte-check: pure CRLF, no bare LF, no BOM
- [ ] Compile: `.\compile.bat src\main.bas` - must be clean
- [ ] Run `cmd /c src\main.exe`; diff output against target (section 6 below) - must match exactly
- [ ] Do NOT commit (repo has unrelated staged files in `csharp/`, `go/`)
- **Compiles:** yes

### Deliberate deviations

| Deviation | Reason |
| --- | --- |
| Null-item validation skipped | FreeBASIC value-type UDT arrays have no null |
| No `ParseInt`/`ParseDouble` methods | Existing code uses `Val()` inline - minimal changes |
| `Split` made private alongside `ProcessLine` | Internal helpers are private in canonical form |
| Validation = `Print` + `End` | FreeBASIC has no custom-message exceptions |
| Java/C# dict style (no quotes) | Primary canonical per migration.md items 10/12 |

---

## Analysis

Session: 2026-10-16 15:34-16:16 UTC, working dir `E:\Uebungen\Code Katas\My Katas\Warehouse Desk\work.noback`
The session ended with `action_result state=failed` (`effect_recovery_failed` / "Action cancelled"),
final projection entry `outcome: {cause: interrupt, type: discarded}`. The agent's own last
reasoning states the `write_file` calls for the migrated sources were never made. All work was
reverted / never landed - the repo is at baseline (verified: `git status` shows no freebasic
changes; `main.bas` still calls `app.SeedData()` / `app.RunDemoDay()`).

## 1. Task (user's original request)

> "@docs/context.md and @docs/migration.md run the migration for freebasic. make minimal changes to existing code"

`docs/migration.md` ("Migration: TypeScript -> Canonical Form", 15 items) describes how to bring a
variant in line with the canonical implementations (Java, Python, C#). The task: apply the same
migration to the **FreeBASIC** variant (`freebasic/src/{main,warehouse,dict,list}.bas`), keeping
changes minimal. Reference implementations already read: Java, Python, C#, PHP, Go, and the
(already migrated) TypeScript.

`docs/context.md` unification rules: same class/module names, same method names, same method
order, same test names/values, similar formatting.

## 2. The plan (agent's todo list)

1. Smoke-test FreeBASIC constructs (array params to UDT methods, interleaved access sections,
   Format/Str/InStr) - **completed in the failed session**
2. `dict.bas`: add `Clear` to the 3 dict types; `PrintKeyValues` -> `{k=v, k=v}` format
3. `list.bas`: add `Clear` + `Contains` to `StringList`; `PrintItemsOneLine` -> `[a, b]` format
4. `warehouse.bas`: `SeedItem` type; `SeedData(items, cash, orderNumber)` with clears+validation;
   `Process` replaces `RunDemoDay`; `ProcessLine` private; `FormatDouble`; DUMP/report formatting
5. `main.bas`: pass seed items + commands to app; call `Process` + `PrintEndOfDayReport`
6. Convert files to CRLF, compile and run; verify output matches canonical (Java/Python/C#) exactly

## 3. Migration item mapping (15 items -> FreeBASIC)

| # | migration.md item | FreeBASIC action |
| --- | --- | --- |
| 1 | `seedData()` must accept parameters | `SeedData(items() As SeedItem, startingCash As Double, startingOrderNumber As Integer)` |
| 2 | Add `SeedItem` type | `Type SeedItem: sku As String, price As Double, stock As Integer` before `WarehouseDeskApp` in warehouse.bas |
| 3 | Replace `runDemoDay()` with `process()` | `Sub WarehouseDeskApp.Process(commands() As String)` loops `ProcessLine`; commands + `PrintEndOfDayReport()` move to main.bas |
| 4 | Make `processLine` private | `Declare Sub ProcessLine` moved to a `private:` section of the Type |
| 5 | `seedData()` clears all 7 collections | `stock/reserved/price/orderStatus/orderSku/orderQty/eventLog.Clear()`; requires new `Clear` (count = 0) on IntegerDict, DoubleDict, StringDict, StringList |
| 6 | Input validation in `seedData()` | blank sku, negative price, negative stock, duplicate sku (via new `StringList.Contains`). **Null-item check not representable** with value-type UDT arrays - skipped deliberately, document the deviation |
| 7 | Update main | main.bas builds `items(0 To 3) As SeedItem` and `commands(0 To 8) As String`, calls `app.SeedData(items(), 300.0, 1001)`, `app.Process(commands())`, `app.PrintEndOfDayReport()` |
| 8 | Event-log doubles `15` -> `15.0` | new private `FormatDouble(value As Double)`: `Str(value)`, append `.0` if no `.`; used in RECV (`at ...`) and SELL (`amount=...`) |
| 9 | DUMP `cashBalance=384` -> `384.0` | `Print "cashBalance=" + FormatDouble(cashBalance)` |
| 10 | DUMP map format `{k=v, k=v}` | rewrite `PrintKeyValues` in all 3 dict types to build `{k=v, k=v}` (string build + single `Print s`) |
| 11 | comma-separator spaces | N/A: FreeBASIC `Print a; b` concatenates without spaces; verified `Str()` adds **no** leading space (unlike QBasic) |
| 12 | Low stock `[STAPLER]` | rewrite `StringList.PrintItemsOneLine` to build `[a, b]`, print with trailing `;` (no newline) |
| 13 | Method ordering | canonical relative order: SeedData, Process, ProcessLine (private), Split (private), FormatDouble (private), FormatFixed2 (private), PrintEndOfDayReport. Remove RunDemoDay. Interleaved `private:`/`public:` sections in the Type verified to compile |
| 14 | TypeScript version bump | N/A for FreeBASIC (no package.json) |
| 15 | CANCEL `sku \|\| ""` cleanup | N/A: FreeBASIC dicts use `Get(key, default)` - idiomatic equivalent, keep as-is |

Plus (output parity): report `cash balance: 384.00` - fixed 2 decimals via new private
`FormatFixed2(value As Double)` (see gotcha 2 below - `Print Using` is not exact).

## 4. FreeBASIC gotchas established by the session's smoke tests (fbc 1.10.1)

1. **No `Format()` function** in FreeBASIC (compile error 42). Do not use it.
2. **`Print Using` is quirky**: `"###.00"` treats `0` as literal text and rounds to integer
   (384.56 -> `385.00`); `"###.##"` works but pads the integer part with leading spaces
   (3.5 -> `3.50`, 12.34 -> `12.00`). Neither is canonical-exact -> use a helper function
   (`FormatFixed2`: `CLng(value*100)`, split into sign/whole/cents, `Right("0" + Str(cents Mod 100), 2)`).
3. **`Str()` is clean**: no leading space for positives (`Str(384.0)` = `384`, `Str(2.2)` = `2.2`).
   No `Trim(Str(...))` needed anywhere.
4. **Type name `App` collides** with something built-in ("Duplicated definition") - irrelevant for
   the real code, which uses `WarehouseDeskApp`.
5. **Array parameters to UDT methods work**: `Declare Sub Process(commands() As String)`,
   `Declare Sub SeedData(items() As SeedItem, ...)`; call with `app.Process(commands())`,
   `app.SeedData(items(), 300.0, 1001)`; iterate with `LBound`/`UBound`.
6. **Interleaved `private:`/`public:` sections inside a `Type` compile** - allows canonical method order.
7. **Private UDT members are module-scoped**: dict.bas/list.bas/warehouse.bas/main.bas are one module
   after `#include`, so existing direct access to `orderStatus.count` / `orderStatus.values(i)`
   keeps working; `private:` on `ProcessLine`/`Split` documents the API shape.
8. **Errors**: FreeBASIC has no exceptions with custom messages. Validation failure =
   `Print "<canonical message>"` then `End` (aborts the program).
9. **Line endings**: all 4 `.bas` files are pure CRLF, no BOM; `git core.autocrlf=true`.
   `edit` does exact matching (CRLF mismatch fails) and `write_file` emits LF - so: rewrite files,
   then normalize CRLF->LF->CRLF via a PowerShell script, write back UTF-8 **without** BOM.
10. `main.exe` is gitignored (untracked build artifact) - rebuild locally to verify, no commit concerns.
11. Run the exe via `cmd /c` in PowerShell (direct path invocation misbehaves).
12. Compile with the repo's own script: `.\compile.bat src\main.bas` (= `fbc -mt -g -exx -w all -w error -i inc -p lib`).

## 5. Baseline (current, pre-migration) output - captured by the session

```
---- dump ----
stock=PEN-BLACK=30 PEN-BLUE=25 NOTE-A5=6 STAPLER=2 
reserved=PEN-BLACK=0 PEN-BLUE=0 NOTE-A5=0 STAPLER=0 
orders=O1001=SHIPPED O1002=CANCELLED O1003=SHIPPED O1004=SHIPPED 
cashBalance=384

==== end of day ====
orders shipped: 3
orders backordered: 0
orders cancelled: 1
cash balance: 384
low stock skus: STAPLER 
events:
 - received 5 of NOTE-A5 at 2.2
 - order O1001 shipped to alice amount=15
 - order O1002 backordered for bob sku=STAPLER qty=5
 - cancelled backorder O1002
 - count STAPLER onHand=4 reserved=0 available=4
 - order O1003 shipped to carol amount=24
 - order O1004 shipped to dan amount=56
 - count NOTE-A5 onHand=6 reserved=0 available=6
```

## 6. Target (canonical Java/C#/Python) output - the acceptance criterion

```
---- dump ----
stock={PEN-BLACK=30, PEN-BLUE=25, NOTE-A5=6, STAPLER=2}
reserved={PEN-BLACK=0, PEN-BLUE=0, NOTE-A5=0, STAPLER=0}
orders={O1001=SHIPPED, O1002=CANCELLED, O1003=SHIPPED, O1004=SHIPPED}
cashBalance=384.0

==== end of day ====
orders shipped: 3
orders backordered: 0
orders cancelled: 1
cash balance: 384.00
low stock skus: [STAPLER]

events:
 - received 5 of NOTE-A5 at 2.2
 - order O1001 shipped to alice amount=15.0
 - order O1002 backordered for bob sku=STAPLER qty=5
 - cancelled backorder O1002
 - count STAPLER onHand=4 reserved=0 available=4
 - order O1003 shipped to carol amount=24.0
 - order O1004 shipped to dan amount=56.0
 - count NOTE-A5 onHand=6 reserved=0 available=6
```

(Arithmetic verified: 300 - 5*2.2 + 1.5*10 + 12*2 + 4*14 = 384.0 exactly in IEEE double;
Java prints `cashBalance=384.0`, `%.2f` -> `384.00`.)

## 7. Per-file steps

### dict.bas

- IntegerDict: add `Declare Sub Clear()` (after Constructor) + `Sub IntegerDict.Clear(): count = 0`;
  rewrite `PrintKeyValues` to `{k=v, k=v}` via string build (`Str(values(i))` for Integer values).
- DoubleDict: same `Clear`; same `PrintKeyValues` rewrite (`Str(values(i))`).
- StringDict: same `Clear`; same `PrintKeyValues` rewrite (`values(i)` directly, no Str).
- Everything else unchanged (keep leading blank line; CRLF).

### list.bas

- StringList: add `Declare Sub Clear()` + impl (`count = 0`);
  add `Declare Function Contains(item As String) As Integer` + impl (linear scan, return 1/0);
  rewrite `PrintItemsOneLine` to build `[a, b]` and `Print s;` (trailing `;`, no newline).
- `PrintItems` unchanged (already canonical `- item` per line).

### warehouse.bas

- Add `Type SeedItem` (sku/price/stock) after the `#include`s, before `WarehouseDeskApp`.
- Type `WarehouseDeskApp`: keep fields; interleaved sections -
  `public:` `SeedData(items() As SeedItem, startingCash As Double, startingOrderNumber As Integer)`,
  `Process(commands() As String)`;
  `private:` `ProcessLine(cmdLine As String)`, `Split(...)`, `FormatDouble(value As Double) As String`,
  `FormatFixed2(value As Double) As String`;
  `public:` `PrintEndOfDayReport()`.
- `SeedData`: clear all 7 collections; loop `LBound(items)..UBound(items)`; `sku = Trim(items(i).sku)`;
  validate blank sku / negative price / negative stock / duplicate sku (via `seenSkus As StringList` +
  `Contains`), each failure `Print "<canonical message>"` + `End`; then
  `stock.Set(sku, items(i).stock)`, `price.Set(sku, items(i).price)`, `reserved.Set(sku, 0)`;
  finally `cashBalance = startingCash`, `nextOrderNumber = startingOrderNumber`.
- `Process(commands() As String)`: `For i = LBound(commands) To UBound(commands): ProcessLine(commands(i))`.
- `ProcessLine`: RECV event uses `FormatDouble(unitCost)`; SELL shipped event uses
  `FormatDouble(orderTotal)`; DUMP: `Print "stock=";` + `stock.PrintKeyValues()` (same for reserved,
  orders), `Print "cashBalance=" + FormatDouble(cashBalance)`; CANCEL/COUNT/unknown unchanged.
- `Split`: unchanged body (now private).
- `FormatDouble`: `Dim s As String = Str(value): If InStr(s, ".") = 0 Then s = s + ".0": Return s`.
- `FormatFixed2`: `Dim cents As Long = CLng(value * 100)`; handle sign; return
  `sign + Str(cents \ 100) + "." + Right("0" + Str(cents Mod 100), 2)`.
- `PrintEndOfDayReport`: only change is `Print "cash balance: " + FormatFixed2(cashBalance)`;
  low-stock lines and `eventLog.PrintItems()` unchanged (new PrintItemsOneLine does the work).
- Definition order: SeedData, Process, ProcessLine, Split, FormatDouble, FormatFixed2, PrintEndOfDayReport.

### main.bas

```basic
#include "warehouse.bas"

Dim app As WarehouseDeskApp

Dim items(0 To 3) As SeedItem
items(0).sku = "PEN-BLACK" : items(0).price = 1.5 : items(0).stock = 40
items(1).sku = "PEN-BLUE"  : items(1).price = 1.6 : items(1).stock = 25
items(2).sku = "NOTE-A5"   : items(2).price = 4.0 : items(2).stock = 15
items(3).sku = "STAPLER"   : items(3).price = 12.0 : items(3).stock = 4

app.SeedData(items(), 300.0, 1001)

Dim commands(0 To 8) As String
commands(0) = "RECV;NOTE-A5;5;2.20"
commands(1) = "SELL;alice;PEN-BLACK;10"
commands(2) = "SELL;bob;STAPLER;5"
commands(3) = "CANCEL;O1002"
commands(4) = "COUNT;STAPLER"
commands(5) = "SELL;carol;STAPLER;2"
commands(6) = "SELL;dan;NOTE-A5;14"
commands(7) = "COUNT;NOTE-A5"
commands(8) = "DUMP"

app.Process(commands())
app.PrintEndOfDayReport()
```

(The journal's draft used one assignment per line - equivalent; keep one-per-line to match repo style.)

## 8. Execution & verification steps (final todo item)

1. Rewrite the 4 files (write_file, LF), then convert each to CRLF, UTF-8 no BOM:
   `$t = [IO.File]::ReadAllText($p) -replace "`r`n","`n" -replace "`n","`r`n";
    [IO.File]::WriteAllText($p, $t, [Text.UTF8Encoding]::new($false))`
2. Byte-check: pure CRLF, no bare LF, no BOM (script pattern already used in the session).
3. `cd freebasic; .\compile.bat src\main.bas` - must compile clean (`-w all -w error`).
4. Run `cmd /c src\main.exe`; diff output against the target in section 6 - must match exactly.
5. Do NOT commit (repo has unrelated pre-existing staged/modified files: csharp/, go/).

## 9. Deliberate deviations / notes

- **Null-item validation skipped**: not representable with `items() As SeedItem` value arrays
  (FreeBASIC UDTs have no null). Using `SeedItem Ptr` arrays was considered and rejected as
  un-idiomatic/clunky for the kata. Document this in the final summary.
- **No ParseInt/ParseDouble methods added**: existing code uses `Val()` inline; migration item 13's
  ordering is honored for the methods that exist (minimal changes).
- **`Split` made private** alongside `ProcessLine` (internal helpers are private in canonical form).
- **Validation failure = `Print` message + `End`** (no custom-message exceptions in FreeBASIC).
- **Python's dict/list repr has quotes** (`{'PEN-BLACK': 30}`, `['STAPLER']`); FreeBASIC follows the
  Java/C# style (no quotes), which is the primary canonical per migration.md item 10/12.
- Session also read `feature.md` (stock reservation with expiry is a *future* feature - NOT part of
  this migration) and the `harness/` folder; neither affects the plan.
