class ltcl_number definition final
  for testing
  duration short
  risk level harmless.

  private section.
    methods rounding   for testing.
    methods clamping   for testing.
    methods ranges     for testing.
    methods percentage for testing.
    methods grouping   for testing.
endclass.


class ltcl_number implementation.
  method rounding.
    cl_abap_unit_assert=>assert_equals(
      exp = conv decfloat34( '2.35' )
      act = zcl_au_number=>round_to( iv_value = '2.345' iv_decimals = 2 ) ).
  endmethod.

  method clamping.
    cl_abap_unit_assert=>assert_equals(
      exp = conv decfloat34( '10' )
      act = zcl_au_number=>clamp( iv_value = '42' iv_min = '0' iv_max = '10' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = conv decfloat34( '5' )
      act = zcl_au_number=>clamp( iv_value = '5' iv_min = '0' iv_max = '10' ) ).
  endmethod.

  method ranges.
    cl_abap_unit_assert=>assert_true(
      zcl_au_number=>in_range( iv_value = '5' iv_min = '1' iv_max = '10' ) ).
    cl_abap_unit_assert=>assert_false(
      zcl_au_number=>in_range( iv_value = '11' iv_min = '1' iv_max = '10' ) ).
  endmethod.

  method percentage.
    cl_abap_unit_assert=>assert_equals(
      exp = conv decfloat34( '25.00' )
      act = zcl_au_number=>percentage( iv_part = '1' iv_whole = '4' ) ).
    " division by zero is guarded
    cl_abap_unit_assert=>assert_equals(
      exp = conv decfloat34( '0' )
      act = zcl_au_number=>percentage( iv_part = '1' iv_whole = '0' ) ).
  endmethod.

  method grouping.
    cl_abap_unit_assert=>assert_equals(
      exp = `1,234,567.50`
      act = zcl_au_number=>format_grouped( '1234567.5' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `-1.234.567,50`
      act = zcl_au_number=>format_grouped( iv_value         = '-1234567.5'
                                           iv_thousands_sep = '.'
                                           iv_decimal_sep   = ',' ) ).
  endmethod.
endclass.
