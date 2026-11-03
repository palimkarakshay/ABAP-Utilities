class ltcl_diff definition final
  for testing
  duration short
  risk level harmless.

  private section.
    methods changed_line for testing.
    methods pure_insert  for testing.
    methods equality     for testing.

    methods count
      importing it_diff type zcl_au_diff=>tt_line iv_kind type c
      returning value(rv) type i.
endclass.


class ltcl_diff implementation.
  method count.
    rv = lines( value zcl_au_diff=>tt_line( for d in it_diff where ( kind = iv_kind ) ( d ) ) ).
  endmethod.

  method changed_line.
    data(lt) = zcl_au_diff=>tables(
      it_a = value #( ( `line1` ) ( `line2` )         ( `line3` ) )
      it_b = value #( ( `line1` ) ( `line2 changed` ) ( `line3` ) ) ).
    " line1 + line3 unchanged; line2 replaced -> one '-' and one '+'
    cl_abap_unit_assert=>assert_equals( exp = 2 act = count( it_diff = lt iv_kind = ' ' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = count( it_diff = lt iv_kind = '-' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = count( it_diff = lt iv_kind = '+' ) ).
  endmethod.

  method pure_insert.
    data(lt) = zcl_au_diff=>tables( it_a = value #( ( `x` ) )
                                    it_b = value #( ( `x` ) ( `y` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = count( it_diff = lt iv_kind = ' ' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = count( it_diff = lt iv_kind = '+' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = count( it_diff = lt iv_kind = '-' ) ).
  endmethod.

  method equality.
    data(lt_a) = value string_table( ( `a` ) ( `b` ) ).
    cl_abap_unit_assert=>assert_true(  zcl_au_diff=>are_equal( it_a = lt_a it_b = lt_a ) ).
    cl_abap_unit_assert=>assert_false( zcl_au_diff=>are_equal( it_a = lt_a it_b = value #( ( `a` ) ) ) ).
  endmethod.
endclass.
