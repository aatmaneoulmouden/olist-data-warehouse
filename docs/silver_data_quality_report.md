# Data Quality Report

## Purpose

This document summarizes the data quality issues identified in the Olist source datasets during the Silver layer implementation. It also documents the actions taken by the ETL process to address or preserve these issues.

---

## Orders

### Delivered orders with missing customer delivery date

Records found: 8

Action:
- Preserved the source data.
- No correction applied because the actual delivery date cannot be determined.

Reason:
- Modifying the timestamp would fabricate business data.

### Orders delivered before approval

Records found: 1,359

Action:
- Preserved the source data.

Reason:
- It is impossible to determine which timestamp is incorrect.

### Customer delivery before carrier handoff

Records found: 23

Action:
- Preserved the source data.

Reason:
- The correct sequence cannot be inferred from the available data.

---

## Products

### Missing category translations

Records found: 2

Action:
- Inserted the missing categories into the translation lookup table.
- Assigned the placeholder value 'unknown' for the English translation.

Reason:
- Preserves referential integrity while clearly indicating that the source translation is unavailable.

---

## Geolocations

### Duplicate ZIP codes

Action:
- Deduplicated using ROW_NUMBER(), keeping one standardized record per ZIP code.

### Missing ZIP codes referenced by Customers

Action:
- Inserted the missing ZIP codes using the corresponding customer city and state.

### Missing ZIP codes referenced by Sellers

Action:
- Inserted the missing ZIP codes using the corresponding seller city and state.