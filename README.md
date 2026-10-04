# PL/SQL Project

This repository documents my learning journey with PL/SQL. It combines coursework, practical exercises, and a pet project developed while building a foundation in Oracle database programming.

## Course Summary

- **8 modules** covering the core concepts and techniques of PL/SQL
- **[Modules](Modules/)** containing the homework and practical assignments for each module
- **[Pet Project](Pet%20Project/)** applying the knowledge from the course in a larger, hands-on project

The project is intended to show my progress from fundamental PL/SQL syntax and database concepts to writing more structured and practical database solutions.

## Pet-Project Structure

```
Pet Project/
│
├── 01. Logging layer
│   ├── Sequence.sql                       → log_seq (ID generator for logs)
│   ├── Table_Logs.sql                     → logs (audit/log table)
│   ├── Procedure_to_log.sql               → to_log (autonomous-transaction writer)
│   ├── log_utils_p_specification.sql      → log_utils package spec
│   └── log_utils_p_body.sql               → log_utils package body
│
├── 02. Data storage
│   ├── Table_employee_history.sql         → employees_history (terminated employees)
│   ├── Table_cur_exchange.sql             → cur_exchange (NBU exchange rates)
│   └── Table_sys_params.sql               → sys_params (config) + JOB_API_NBU_SYNC (scheduler job)
│
├── 03. Triggers
│   └── trigger_new_employee.sql           → trg_employee_id_auto (auto employee_id)
│
└── 04. Business logic
    ├── util_project_specification.sql     → util_project package spec (public API)
    └── util_project_body.sql              → util_project package body (implementation)
```
It provides:

- **Employee lifecycle management** — hire, update, terminate (with history archiving)
- **Schema utilities** — copy table structures/data between schemas
- **Currency rates integration** — daily sync of exchange rates from the National Bank of Ukraine (NBU) API
- **Centralized logging** — every operation writes start / finish / error records to a `logs` table
- **Business rule** — data changes are allowed only during working hours (Mon–Fri, 08:00–18:00)

> Standalone `procedure_*.sql` and `function_*.sql` files (folder 'Procedures&Functions') are excluded from this overview — their logic is consolidated in the `util_project` package. The only exception is `Procedure_to_log.sql`, which is the logging core.

## Deployment order

Objects must be created in dependency order:

| # | File | Object | Type |
|---|------|--------|------|
| 1 | `Sequence.sql` | `log_seq` | Sequence |
| 2 | `Table_Logs.sql` | `logs` | Table |
| 3 | `Procedure_to_log.sql` | `to_log` | Procedure |
| 4 | `log_utils_p_specification.sql` | `log_utils` | Package spec |
| 5 | `log_utils_p_body.sql` | `log_utils` | Package body |
| 6 | `Table_employee_history.sql` | `employees_history` | Table |
| 7 | `Table_cur_exchange.sql` | `cur_exchange` | Table |
| 8 | `trigger_new_employee.sql` | `trg_employee_id_auto` | Trigger |
| 9 | `util_project_specification.sql` | `util_project` | Package spec |
| 10 | `util_project_body.sql` | `util_project` | Package body |
| 11 | `Table_sys_params.sql` | `sys_params` + `JOB_API_NBU_SYNC` | Table + Scheduler job |

**Prerequisites:** HR schema tables (`employees`, `jobs`, `departments`)

##  Functional Flows

###  Centralized logging

Every logged event follows the same path: **caller → `log_utils` (procedures from log_utils package) → `to_log` (procedure to_log → `log_seq` (Sequence) → `logs` (table)**.

1. A business procedure calls one of the `log_utils` procedures, passing its own name in `p_proc_name`:
   - `log_utils.log_start` — at the beginning of the procedure
   - `log_utils.log_finish` — after successful completion
   - `log_utils.log_error` — in the `EXCEPTION` block, passing `SQLERRM` or a custom error text
2. `log_utils` builds the message text:
   - if `p_text` is passed, it is used as is;
   - otherwise a default text is generated: `Start of procedure: …`, `Finish of procedure: …` or `Error in procedure: … - Error: …`.
3. `log_utils` calls the standalone procedure `to_log(p_appl_proc, p_message)`.
4. `to_log` takes the next ID from sequence `log_seq.NEXTVAL`.
5. `to_log` inserts a row into the `logs` table: `id`, `appl_proc` (procedure name), `message`; `log_date` is filled automatically with `SYSDATE` (column default).
6. `to_log` runs as an **autonomous transaction** (`PRAGMA AUTONOMOUS_TRANSACTION`) and commits immediately. The log record is therefore saved **independently of the caller's transaction** — even when the caller fails and executes `ROLLBACK`, the error log remains in `logs`.

Result: the `logs` table holds the full execution history of all procedures — `SELECT * FROM logs ORDER BY id DESC`.

---

###  Business rule — working hours (`work_life_balance`)

1. Each employee-changing procedure (`add_employee`, `change_attribute_employee`, `fire_an_employee`) calls `util_project.work_life_balance` right after `log_start`, **before any data change**.
2. `work_life_balance` logs its own start via `log_utils.log_start`.
3. It reads the current day of week (`TO_CHAR(SYSDATE, 'd')`) and time (`TO_CHAR(SYSDATE, 'HH24:MI')`).
4. If the day is 1–5 and the time is between `18:01` and `07:59` , the procedure ends silently and the caller continues.
5. Otherwise it raises the internal exception `v_is_not_working_hours`, which:
   - writes an error into `logs` via `log_utils.log_error`;
   - raises `ORA-20001` "You cannot implement changes now…".
6. The error propagates to the calling procedure, which logs it again via its own `WHEN OTHERS` block and re-raises — **no data is changed**.

---

###  Employee lifecycle management

#### a) Hire — `util_project.add_employee`

1. `log_utils.log_start('add_employee')` → record in `logs`.
2. `util_project.work_life_balance` → check working hours.
3. Validate the job: `SELECT COUNT(*) FROM jobs WHERE job_id = p_job_id`.
   - not found → `v_non_existent_job` → `ORA-20001`.
4. Validate salary: read `min_salary`, `max_salary` from `jobs`; if `p_salary` is out of range → `v_salary_error` → `ORA-20001`.
5. Validate the department: `SELECT COUNT(*) FROM departments`; not found → `v_non_existent_department` → `ORA-20001`.
6. `INSERT INTO employees` **without** `employee_id`.
7. Trigger `trg_employee_id_auto` (BEFORE INSERT) fires: `employee_id` is NULL → it is set to `MAX(employee_id) + 1`.
8. `DBMS_OUTPUT` prints a confirmation, then `COMMIT`.
9. `log_utils.log_finish('add_employee')` → record in `logs`.
10. On any error: `log_utils.log_error` writes the reason into `logs`, then the error is raised to the caller.

#### b) Update — `util_project.change_attribute_employee`

1. `log_utils.log_start('change_attribute_employee')` → record in `logs`.
2. `util_project.work_life_balance` → check working hours.
3. Check the employee exists in `employees`; not found → `ORA-20001`.
4. Check that at least one attribute is passed; all NULL → `ORA-20002`.
5. Run a dynamic `UPDATE employees` via `EXECUTE IMMEDIATE … USING` with bind variables. Each column is set to `NVL(:param, current_value)`, so **only passed attributes change**; the rest stay the same.
6. `COMMIT` → `log_utils.log_finish('change_attribute_employee')` → record in `logs`.
7. On error → `log_utils.log_error` → raise.

#### c) Terminate — `util_project.fire_an_employee`

1. `log_utils.log_start('fire_an_employee')` → record in `logs`.
2. `util_project.work_life_balance` → check working hours.
3. Check the employee exists; not found → `ORA-20001`.
4. Read the employee row from `employees` into local variables.
5. `INSERT INTO employees_history` — copy of the employee data + `fire_date` (default `SYSDATE`) + `status` (default `Terminated`).
6. `DELETE FROM employees` for that `employee_id`.
7. On error → `log_utils.log_error` → `ROLLBACK` (history insert and delete are both undone) → raise.

Result: active employees live in `employees`; former employees move to `employees_history` with the termination date and status.

---

###  Schema utilities

#### a) Split a list into rows — `util_project.table_from_list`

1. Input: a string like `'employees, jobs'` and a separator (default `,`).
2. `REGEXP_SUBSTR` + `CONNECT BY LEVEL` split the string into parts; `TRIM` removes spaces.
3. Results are fetched with `BULK COLLECT` and returned row by row via `PIPE ROW`.
4. Used as a table: `SELECT * FROM TABLE(util_project.table_from_list('a,b'))`.
5. Reused by `copy_table` (table names) and `api_nbu_sync` (currency codes).

#### b) Copy tables between schemas — `util_project.copy_table`

1. `log_utils.log_start('copy_table')` → record in `logs`.
2. `util_project.work_life_balance` → check working hours.
3. Table names from `p_list_table` are split by `table_from_list` and converted to upper case.
4. Column metadata is read from the `all_tab_columns` dictionary view for the source schema.
5. For each table a `CREATE TABLE target.table (col type(size), …)` statement is built with `LISTAGG`, handling `VARCHAR2/CHAR` (length), `NUMBER` (precision, scale) and `DATE`.
6. `EXECUTE IMMEDIATE` creates the table in the target schema.
7. If `p_copy_data = TRUE` → `INSERT INTO target.table SELECT * FROM source.table` + `COMMIT`.
8. Success → counter `v_ok_cnt` +1 and `log_utils.log_finish('copy_table')` → record in `logs`.
9. Failure on a table (e.g. it already exists) → counter `v_err_cnt` +1, `log_utils.log_error` → record in `logs`, and the loop **continues with the next table**.
10. `po_result` = `Copied: N, skipped: M`; `log_utils.log_finish('copy_table')` → record in `logs`.

---

###  Currency rates integration (NBU API)

1. **Configuration.** The list of currencies is stored in `sys_params`: `param_name = 'list_currencies'`, `value_text = 'USD,EUR,…'`.
2. **Schedule.** Scheduler job `JOB_API_NBU_SYNC` (created in `Table_sys_params.sql`) runs `api_nbu_sync` every day at **06:00**.
3. `api_nbu_sync` reads `list_currencies` from `sys_params`.
   - Parameter missing → `log_utils.log_error` → `ORA-20001`.
4. The currency string is split into rows by `table_from_list`.
5. For each currency, `get_needed_curr(p_valcode, p_date = SYSDATE)` is called:
   - builds the URL `https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode=USD&date=YYYYMMDD&json`;
   - calls the external function `sys.get_nbu` (HTTP request);
   - returns the JSON response as `VARCHAR2`.
6. `JSON_TABLE` parses the JSON array into columns: `r030`, `txt`, `rate`, `cc → cur`, `exchangedate` (string → `DATE` via `TO_DATE(…, 'DD.MM.YYYY')`).
7. The row is inserted into `cur_exchange`; `load_date` is filled with `SYSDATE`. The unique key `(cur, exchangedate)` guarantees one rate per currency per day.
8. After all currencies are processed → `COMMIT` → `log_utils.log_finish('api_nbu_sync')` → record in `logs`.

Result: `cur_exchange` accumulates the daily rate history for every configured currency.

---


##  Usage Examples

```sql
-- Configure currencies
INSERT INTO sys_params (param_name, value_text, param_descr)
VALUES ('list_currencies', 'USD,EUR,PLN', 'Currencies for NBU sync');
COMMIT;

-- Hire
BEGIN
  util_project.add_employee(
    p_first_name => 'Olena', p_last_name => 'Koval',
    p_email => 'OKOVAL', p_phone_number => '050.123.4567',
    p_job_id => 'IT_PROG', p_salary => 6000, p_department_id => 60);
END;
/

-- Update salary only
BEGIN util_project.change_attribute_employee(p_employee_id => 207, p_salary => 7000); END;
/

-- Terminate
BEGIN util_project.fire_an_employee(p_employee_id => 207); END;
/

-- Split list
SELECT * FROM TABLE(util_project.table_from_list('a, b, c'));

-- Manual currency sync & check
BEGIN util_project.api_nbu_sync; END;
/
SELECT * FROM cur_exchange ORDER BY exchangedate DESC;

-- Review logs
SELECT * FROM logs ORDER BY id DESC;
```

---
