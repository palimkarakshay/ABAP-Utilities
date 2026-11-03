class ltcl_date definition final
  for testing
  duration short
  risk level harmless.

  private section.
    methods diff           for testing.
    methods add_months_eom for testing.
    methods month_bounds   for testing.
    methods weekday_iso    for testing.
    methods weekend        for testing.
    methods workdays       for testing.
    methods iso_roundtrip  for testing.
    methods age_calc       for testing.
endclass.


class ltcl_date implementation.
  method diff.
    cl_abap_unit_assert=>assert_equals(
      exp = 9
      act = zcl_au_date=>days_between( iv_from = '20260101' iv_to = '20260110' ) ).
  endmethod.

  method add_months_eom.
    " 31-Jan + 1 month must clamp to 28-Feb (2026 is not a leap year)
    cl_abap_unit_assert=>assert_equals(
      exp = conv d( '20260228' )
      act = zcl_au_date=>add_months( iv_date = '20260131' iv_months = 1 ) ).
    " crossing the year boundary backwards
    cl_abap_unit_assert=>assert_equals(
      exp = conv d( '20251115' )
      act = zcl_au_date=>add_months( iv_date = '20260115' iv_months = -2 ) ).
  endmethod.

  method month_bounds.
    cl_abap_unit_assert=>assert_equals(
      exp = conv d( '20260201' )
      act = zcl_au_date=>first_day_of_month( '20260215' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = conv d( '20260228' )
      act = zcl_au_date=>last_day_of_month( '20260210' ) ).
  endmethod.

  method weekday_iso.
    " 2026-05-24 is a Sunday
    cl_abap_unit_assert=>assert_equals(
      exp = 7
      act = zcl_au_date=>weekday( '20260524' ) ).
    " 2026-05-25 is a Monday
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = zcl_au_date=>weekday( '20260525' ) ).
  endmethod.

  method weekend.
    cl_abap_unit_assert=>assert_true( zcl_au_date=>is_weekend( '20260524' ) ).
    cl_abap_unit_assert=>assert_false( zcl_au_date=>is_weekend( '20260525' ) ).
  endmethod.

  method workdays.
    " Mon 2026-05-25 .. Sun 2026-05-31 -> 5 working days
    cl_abap_unit_assert=>assert_equals(
      exp = 5
      act = zcl_au_date=>workdays_between( iv_from = '20260525' iv_to = '20260531' ) ).
  endmethod.

  method iso_roundtrip.
    cl_abap_unit_assert=>assert_equals(
      exp = `2026-05-24`
      act = zcl_au_date=>to_iso( '20260524' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = conv d( '20260524' )
      act = zcl_au_date=>from_iso( `2026-05-24` ) ).
  endmethod.

  method age_calc.
    " birthday already passed this year
    cl_abap_unit_assert=>assert_equals(
      exp = 36
      act = zcl_au_date=>age( iv_birthday = '19900101' iv_on = '20260524' ) ).
    " birthday not yet reached this year
    cl_abap_unit_assert=>assert_equals(
      exp = 35
      act = zcl_au_date=>age( iv_birthday = '19901231' iv_on = '20260524' ) ).
  endmethod.
endclass.
