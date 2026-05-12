# RAP Unmanaged PO Business Object (BTP ABAP Trial)

## Overview
This repository contains a complete **UNMANAGED RAP Business Object** for Purchase Order (PO) management, featuring:
- **PO Header** (root entity) and **PO Line Item** (child entity, composition)
- **Logical delete only** — no physical deletes
- **CRUD operations** with manual consumer-provided keys (no numbering)
- **BTP ABAP trial** compatible, abapGit-ready deployment

## Functional Scope

### Create
- New PO with mandatory key `PO_ID` (CHAR10)
- PO line items with mandatory key `ITEM_NO` (NUMC5)
- Automatic audit trails (CREATED_BY, CREATED_AT)

### Read
- Query POs (default: excludes logically deleted)
- Query PO items by association
- Soft-deleted records hidden by default

### Update
- Modify PO header (vendor, date, currency, status)
- Modify item details (material, quantity, UOM, price)
- Updated audit fields (CHANGED_BY, CHANGED_AT) automatically set

### Delete
- **Logical Delete Only**: Mark records with `IS_DELETED = 'X'`
- PO delete cascades to all associated items
- Item delete affects only that item row

## STRICT CONSTRAINTS

1. **UNMANAGED RAP**: No managed behavior. Manual CRUD in class pool.
2. **NO DRAFT**: No draft annotations, draft tables, or draft actions.
3. **NO Numbering**: Consumer provides `PO_ID` and `ITEM_NO` keys.
4. **ABAP Cloud Compatible**: Uses only released APIs, no classic BAPIs.
5. **abapGit-Ready**: Can be imported directly into ADT via abapGit.

## File Structure

```
RAP_PROJECTS/
├── .abapgit.xml           # abapGit project configuration
├── .gitignore             # Git ignore rules
├── README.md              # This file
└── src/
    ├── zpo_hdr.tabl.xml                # Database table: PO Header
    ├── zpo_itm.tabl.xml                # Database table: PO Item
    ├── zi_po.ddls.asddls               # CDS Interface: PO Header (root)
    ├── zi_po_item.ddls.asddls          # CDS Interface: PO Item (child)
    ├── zc_po.ddls.asddls               # CDS Projection: PO Header
    ├── zc_po_item.ddls.asddls          # CDS Projection: PO Item
    ├── zi_po.bdef.asbdef               # Behavior Definition: Root
    ├── zc_po.bdef.asbdef               # Behavior Projection: Root
    ├── zbp_i_po.clas.abap              # Behavior Implementation Pool (global)
    ├── zbp_i_po.clas.locals_def.abap   # Behavior Implementation (local types)
    ├── zbp_i_po.clas.locals_imp.abap   # Behavior Implementation (methods)
    ├── zbp_i_po.clas.xml               # Class metadata
    ├── zui_po_srv.srvd.xml             # Service Definition
    ├── zui_po_o4.srvb.xml              # OData V4 Service Binding
    ├── ztcl_po_rap_test.clas.abap      # EML Unit Test Class
    └── ztcl_po_rap_test.clas.xml       # Test class metadata
```

## Database Tables

### ZPO_HDR (PO Header)
| Field | Type | Key | Description |
|-------|------|-----|-------------|
| MANDT | CLNT | ✓ | Client |
| PO_ID | CHAR(10) | ✓ | Purchase Order ID (consumer-provided) |
| VENDOR_ID | CHAR(10) | | Vendor ID |
| DOC_DATE | DATS | | Document Date |
| CURRENCY | CUKY | | Currency Code |
| STATUS | CHAR(1) | | PO Status (O=Open, C=Closed, X=Cancelled) |
| IS_DELETED | ABAP_BOOL | | Logical Delete Flag (X=deleted, space=active) |
| CREATED_BY | SYUNAME | | Created by User |
| CREATED_AT | UTCLONG | | Created at Timestamp (UTC) |
| CHANGED_BY | SYUNAME | | Changed by User |
| CHANGED_AT | UTCLONG | | Changed at Timestamp (UTC) |

### ZPO_ITM (PO Item)
| Field | Type | Key | Description |
|-------|------|-----|-------------|
| MANDT | CLNT | ✓ | Client |
| PO_ID | CHAR(10) | ✓ | Purchase Order ID (foreign key) |
| ITEM_NO | NUMC(5) | ✓ | Line Item Number (consumer-provided, e.g., 00010, 00020) |
| MATERIAL | CHAR(18) | | Material Number |
| QUANTITY | QUAN | | Order Quantity |
| UOM | UNIT | | Unit of Measure |
| NET_PRICE | CURR | | Net Price (references CURRENCY from header) |
| CURRENCY | CUKY | | Currency Code |
| PLANT | WERKS_D | | Plant/Facility |
| IS_DELETED | ABAP_BOOL | | Logical Delete Flag |
| CREATED_BY | SYUNAME | | Created by User |
| CREATED_AT | UTCLONG | | Created at Timestamp (UTC) |
| CHANGED_BY | SYUNAME | | Changed by User |
| CHANGED_AT | UTCLONG | | Changed at Timestamp (UTC) |

## Logical Delete Implementation

### Rules
- **Delete PO**: Sets `ZPO_HDR.IS_DELETED = 'X'` AND cascades to set `ZPO_ITM.IS_DELETED = 'X'` for all items.
- **Delete Item**: Sets only `ZPO_ITM.IS_DELETED = 'X'` for that item.
- **Read**: Excludes rows where `IS_DELETED = 'X'` by default (CDS view filter).
- **Physical Rows**: Never deleted; flag indicates logical deletion.

### CDS Views
Both `ZI_PO` and `ZI_PO_ITEM` interface views include:
```cds
where is_deleted = ' '
```
This filter ensures soft-deleted records are not returned to consumers unless explicitly needed.

## RAP Behavior (Unmanaged)

### Root Entity: ZI_PO
- **Operations**: create, update, delete (logical)
- **Association**: `_Items` [0..*] composition of `ZI_PO_ITEM`
- **Key Field**: `PO_ID` (mandatory on create, provided by consumer)
- **Etag**: Based on `CHANGED_AT` for conflict detection

### Child Entity: ZI_PO_ITEM
- **Operations**: create (via `_Items` association), update, delete (logical)
- **Key Fields**: `PO_ID`, `ITEM_NO` (mandatory on create)
- **Etag**: Dependent on parent via `CHANGED_AT`

### Unmanaged Behavior Implementation
The behavior class `ZBP_I_PO` is structured as a class pool with:

1. **`lcl_buffer`** — Transaction buffer for MODIFY requests (static tables)
2. **`lhc_po`** — Root entity handler (`cl_abap_behavior_handler`)
   - `create_po` — Validate key, check duplicate, add to buffer, set audit fields
   - `update_po` — Validate key and not-deleted, update buffer
   - `delete_po` — Add key to logical-delete buffer
   - `create_items` — Create items via `_Items` association
   - `rba_items` — Read items by association (filtered, not deleted)
   - `global_authorization` — Trivial grant-all for demo
   - `lock_po` — Lock master handling

3. **`lhc_po_item`** — Child entity handler
   - `update_item` — Update item (validate not-deleted)
   - `delete_item` — Logical delete item
   - `read_item` — Read items (filtered)

4. **`lsc_po`** — Saver class (`cl_abap_behavior_saver`)
   - `save_modified` — Flushes buffers to DB using ABAP SQL:
     - INSERT for new POs/items
     - UPDATE for modified POs/items
     - UPDATE + SET IS_DELETED for logical deletes (cascade for PO → items)
   - `finalize` — Clear buffers post-commit

## Activation Order

**Follow this sequence in ADT to ensure dependencies resolve correctly:**

1. **Tables** (ABAP Dictionary)
   ```
   Activate: ZPO_HDR
   Activate: ZPO_ITM
   ```

2. **CDS Interface Views**
   ```
   Activate: ZI_PO_ITEM (child, no dependency)
   Activate: ZI_PO (root, depends on ZI_PO_ITEM for composition)
   ```

3. **CDS Projection Views**
   ```
   Activate: ZC_PO_ITEM
   Activate: ZC_PO
   ```

4. **Behavior Definitions**
   ```
   Activate: ZI_PO.BDEF (behavior definition, references ZI_PO CDS)
   Activate: ZC_PO.BDEF (behavior projection, references ZC_PO CDS)
   ```

5. **Behavior Implementation**
   ```
   Activate: ZBP_I_PO.CLAS (behavior implementation class pool)
   ```

6. **Service Exposure**
   ```
   Activate: ZUI_PO_SRV (service definition)
   ```

7. **Service Binding** (Manual Publishing)
   ```
   Right-click ZUI_PO_O4 → Publish
   (Creates OData endpoint; binding is created but may need manual publication)
   ```

## Example OData Requests

### Create PO with 2 Items

**POST** to `https://<btp-instance>.abap.cloud.sap/service/odata/v4/zui_po_srv/PO`

```json
{
  "PO_ID": "PO0000001",
  "VENDOR_ID": "VENDOR01",
  "DOC_DATE": "2024-05-13",
  "CURRENCY": "USD",
  "STATUS": "O",
  "PO": [
    {
      "ITEM_NO": "00010",
      "MATERIAL": "MAT001",
      "QUANTITY": "5.000",
      "UOM": "EA",
      "NET_PRICE": "10.00",
      "CURRENCY": "USD",
      "PLANT": "1000"
    },
    {
      "ITEM_NO": "00020",
      "MATERIAL": "MAT002",
      "QUANTITY": "3.000",
      "UOM": "EA",
      "NET_PRICE": "20.00",
      "CURRENCY": "USD",
      "PLANT": "1000"
    }
  ]
}
```

### Read PO with Items

**GET** `https://<btp-instance>.abap.cloud.sap/service/odata/v4/zui_po_srv/PO('PO0000001')?$expand=PO`

### Update Item Quantity

**PATCH** to `https://<btp-instance>.abap.cloud.sap/service/odata/v4/zui_po_srv/POItem(PO_ID='PO0000001',ITEM_NO='00010')`

```json
{
  "QUANTITY": "10.000"
}
```

### Logical Delete Item

**DELETE** `https://<btp-instance>.abap.cloud.sap/service/odata/v4/zui_po_srv/POItem(PO_ID='PO0000001',ITEM_NO='00020')`

(Actually marks `IS_DELETED = 'X'` in database; record remains but is not returned in future reads)

### Logical Delete PO (Cascades to Items)

**DELETE** `https://<btp-instance>.abap.cloud.sap/service/odata/v4/zui_po_srv/PO('PO0000001')`

(Sets `ZPO_HDR.IS_DELETED = 'X'` and cascades `UPDATE ZPO_ITM SET IS_DELETED = 'X'` for all items of this PO)

## Testing

### Unit Tests (EML-based)

Run the test class `ZTCL_PO_RAP_TEST` to verify:

1. **test_create** — Create PO + 2 items
2. **test_read** — Read PO and confirm 2 items returned
3. **test_update_item** — Update QUANTITY; verify CHANGED_AT updated
4. **test_delete_item** — Logical delete item 00020; re-read → should see 1 item only
5. **test_delete_po** — Logical delete PO; re-read → PO not found (IS_DELETED = 'X')

**Execution:**
```
ADT → ZTCL_PO_RAP_TEST → Right-click → Run as → ABAP Unit Test
```

Expected: All tests PASS (green) ✓

## Deployment to BTP ABAP Trial

### Prerequisites
- BTP trial ABAP instance (ABAP Cloud enabled)
- ADT (ABAP Development Tools) configured
- abapGit plugin installed in ADT

### Steps

1. **Create Offline Package**
   - In ADT, create a new ABAP package (e.g., `ZPO_RAP`)
   - Package type: Development, local package

2. **Import from abapGit**
   - Right-click package → Clone → Enter repository URL
   - OR: Download `.zip` of this repo, extract to local folder, link to local abapGit repo

3. **Activate All Objects**
   - Follow **Activation Order** section above
   - Resolve any missing dependencies

4. **Publish Service Binding**
   - Right-click `ZUI_PO_O4` → Publish
   - Note the OData endpoint URL

5. **Test via OData**
   - Use Postman, curl, or SAP Fiori preview to test requests

## Constraints & Limitations

- **Keys are Consumer-Provided**: No auto-numbering. `PO_ID` and `ITEM_NO` must be specified on create.
- **Logical Delete Only**: No physical DELETEs. Records remain in DB with `IS_DELETED = 'X'`.
- **No Draft**: This is a transactional BO with no draft. Edits are directly persisted.
- **No Versioning**: No multi-version support or time-travel queries.
- **Single-Client Aware**: Tables include MANDT for multi-client support (typical BTP setup).

## Customization / Extension Points

### Add New Fields to PO Header
1. Add field to `ZPO_HDR` table
2. Add field to `ZI_PO` CDS view
3. Add field to `ZC_PO` CDS projection
4. Optionally, add validation in `lhc_po` handler

### Add Validation Rules
Edit `lhc_po~create_po`, `lhc_po~update_po`, or `lhc_po_item` handlers to add business logic.

### Add Status Transitions / Workflows
Extend the `STATUS` field logic in handlers; define allowed transitions.

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Object not found" on CDS view | Unmet dependency (e.g., table not activated) | Follow activation order strictly |
| "Cannot find behavior" | BDEF not activated before CLAS | Activate BDEF before behavior implementation class |
| Delete returns error | Trying to update a deleted PO/item | Validate IS_DELETED = ' ' before modify in handler |
| Lock object not found | Lock master referenced, object not created | Optional: Create lock object `EZPO_HDR` in ABAP Dictionary |

## References

- [SAP ABAP RESTful Application Programming Model (RAP)](https://help.sap.com/doc/abapdocu_latest/latest/en-US/index.htm)
- [ABAP Cloud for SAP BTP Trial](https://www.sap.com/cdc/en/marketing/trial.html?btp=true)
- [abapGit Documentation](https://github.com/abapGit/abapGit/wiki)

---

**Generated**: May 13, 2026  
**Version**: 1.0  
**Author**: RAP Expert (ABAP Cloud Delivery)