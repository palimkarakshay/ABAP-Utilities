class zcl_au_number definition
  public
  final
  create public.

  public section.
    "! Commercial rounding to a number of decimal places.
    "! @parameter iv_mode | rounding mode, see CL_ABAP_MATH constants
    class-methods round_to
      importing
        !iv_value        type decfloat34
        !iv_decimals     type i default 2
        !iv_mode         type i default cl_abap_math=>round_half_up
      returning
        value(rv_result) type decfloat34.

    "! Constrain a value to the closed interval [min, max].
    class-methods clamp
      importing
        !iv_value        type decfloat34
        !iv_min          type decfloat34
        !iv_max          type decfloat34
      returning
        value(rv_result) type decfloat34.

    class-methods in_range
      importing
        !iv_value        type decfloat34
        !iv_min          type decfloat34
        !iv_max          type decfloat34
      returning
        value(rv_result) type abap_bool.

    "! part / whole * 100, rounded to iv_decimals. Returns 0 for whole = 0.
    class-methods percentage
      importing
        !iv_part         type decfloat34
        !iv_whole        type decfloat34
        !iv_decimals     type i default 2
      returning
        value(rv_result) type decfloat34.

    "! Format a number with explicit grouping and decimal separators,
    "! independent of the user's locale (e.g. 1234567.5 -> "1,234,567.50").
    class-methods format_grouped
      importing
        !iv_value          type decfloat34
        !iv_decimals       type i default 2
        !iv_thousands_sep  type c default ','
        !iv_decimal_sep    type c default '.'
      returning
        value(rv_result)   type string.
endclass.


class zcl_au_number implementation.
  method round_to.
    rv_result = round( val  = iv_value
                       dec  = iv_decimals
                       mode = iv_mode ).
  endmethod.


  method clamp.
    rv_result = iv_value.
    if rv_result < iv_min.
      rv_result = iv_min.
    elseif rv_result > iv_max.
      rv_result = iv_max.
    endif.
  endmethod.


  method in_range.
    rv_result = xsdbool( iv_value >= iv_min and iv_value <= iv_max ).
  endmethod.


  method percentage.
    if iv_whole = 0.
      return.
    endif.
    rv_result = round_to( iv_value    = iv_part / iv_whole * 100
                       iv_decimals = iv_decimals ).
  endmethod.


  method format_grouped.
    data(lv_negative) = xsdbool( iv_value < 0 ).
    data(lv_plain)    = |{ abs( iv_value ) decimals = iv_decimals }|.

    split lv_plain at '.' into data(lv_int) data(lv_frac).
    if iv_decimals > 0 and strlen( lv_frac ) < iv_decimals.
      lv_frac = lv_frac && repeat( val = '0' occ = iv_decimals - strlen( lv_frac ) ).
    endif.

    data lv_grouped type string.
    data lv_counter type i.
    data(lv_pos) = strlen( lv_int ).
    while lv_pos > 0.
      lv_pos     = lv_pos - 1.
      lv_grouped = lv_int+lv_pos(1) && lv_grouped.
      lv_counter = lv_counter + 1.
      if lv_counter mod 3 = 0 and lv_pos > 0.
        lv_grouped = iv_thousands_sep && lv_grouped.
      endif.
    endwhile.

    rv_result = lv_grouped.
    if iv_decimals > 0.
      rv_result = rv_result && iv_decimal_sep && lv_frac.
    endif.
    if lv_negative = abap_true.
      rv_result = |-{ rv_result }|.
    endif.
  endmethod.
endclass.
