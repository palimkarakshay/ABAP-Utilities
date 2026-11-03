# Number & Amount — `ZCL_AU_NUMBER`

> Decimal-precise rounding, clamping, percentages and locale-independent
> grouped formatting.

## Objects & dependencies
- `ZCL_AU_NUMBER` — stateless utility (`class-methods`), uses `DECFLOAT34`.
- Depends on: **nothing** → **ABAP Cloud safe**.

## Install (cherry-pick)
Copy `src/number/zcl_au_number.clas.abap` (+ `.clas.xml`, optionally
`.clas.testclasses.abap`) into a class in your package and assign it to your TR.

## How to use

```abap
zcl_au_number=>round_to( iv_value = '2.345' iv_decimals = 2 ).            "2.35
zcl_au_number=>clamp( iv_value = '42' iv_min = '0' iv_max = '10' ).    "10
zcl_au_number=>in_range( iv_value = '5' iv_min = '1' iv_max = '10' ).  "abap_true
zcl_au_number=>percentage( iv_part = '1' iv_whole = '4' ).             "25.00

" Locale-independent grouping (great for files / reports)
zcl_au_number=>format_grouped( '1234567.5' ).                          "1,234,567.50
zcl_au_number=>format_grouped( iv_value         = '-1234567.5'
                               iv_thousands_sep = '.'
                               iv_decimal_sep   = ',' ).               "-1.234.567,50
```

## API
| Method | Purpose |
|--------|---------|
| `round` | commercial rounding (`CL_ABAP_MATH` modes) |
| `clamp` / `in_range` | constrain / test a value against `[min, max]` |
| `percentage` | `part/whole*100`, guards division by zero |
| `format_grouped` | thousands + decimal separators, locale-independent |

## Tests
`zcl_au_number.clas.testclasses.abap` covers rounding, clamping, range checks,
percentage (including the zero-divisor guard) and grouped formatting with custom
separators.

## Extending
For **currency-aware** display (decimal places per currency from `TCURX`), add a
`format_amount( iv_amount, iv_currency )` method backed by a released currency
API. Keep it in a separate method so the dependency-free core stays cloud-safe.
For Excel output use [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx).
