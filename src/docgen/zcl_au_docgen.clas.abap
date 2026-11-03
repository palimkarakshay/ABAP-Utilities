class zcl_au_docgen definition
  public
  final
  create public.

  public section.
    "! Generate a Markdown API reference for a global class/interface from its
    "! RTTI signature (methods, visibility, parameters). Cloud-safe, no source
    "! access required. Pair it with a report or a pipeline step to keep
    "! docs/api in sync with the activated code.
    class-methods for_class
      importing
        !iv_name           type seoclsname
        !iv_only_public    type abap_bool default abap_true
      returning
        value(rv_markdown) type string
      raising
        zcx_au_error.

    "! Same as for_class, concatenated for several classes/interfaces.
    class-methods for_classes
      importing
        !it_names          type seoclsname_t
      returning
        value(rv_markdown) type string
      raising
        zcx_au_error.

  private section.
    class-methods kind_text
      importing
        !iv_parm_kind  type abap_parmkind
      returning
        value(rv_text) type string.

    class-methods visibility_text
      importing
        !iv_visibility type abap_visibility
      returning
        value(rv_text) type string.
endclass.


class zcl_au_docgen implementation.
  method for_classes.
    data lt_parts type string_table.
    loop at it_names into data(lv_name).
      append for_class( lv_name ) to lt_parts.
    endloop.
    rv_markdown = concat_lines_of( table = lt_parts
                                   sep   = repeat( val = cl_abap_char_utilities=>newline occ = 2 ) ).
  endmethod.


  method for_class.
    cl_abap_typedescr=>describe_by_name(
      exporting
        p_name         = iv_name
      receiving
        p_descr_ref    = data(lo_descr)
      exceptions
        type_not_found = 1
        others         = 2 ).
    if sy-subrc <> 0 or lo_descr is not bound.
      zcx_au_error=>raise( |Object { iv_name } not found| ) ##NO_TEXT.
    endif.

    data(lo_objectdescr) = cast cl_abap_objectdescr( lo_descr ).

    data lt_lines type string_table.
    append |# { to_upper( iv_name ) }| to lt_lines.
    append || to lt_lines.
    append |_Generated from RTTI._| to lt_lines.
    append || to lt_lines.
    append |\| Method \| Visibility \| Parameters \|| to lt_lines.
    append |\|--------\|------------\|------------\|| to lt_lines.

    loop at lo_objectdescr->methods into data(ls_method).
      if iv_only_public = abap_true and ls_method-visibility <> cl_abap_objectdescr=>public.
        continue.
      endif.

      data lv_params type string.
      clear lv_params.
      loop at ls_method-parameters into data(ls_param).
        lv_params = lv_params
                 && |`{ to_lower( ls_param-name ) }` _{ kind_text( ls_param-parm_kind ) }_<br>|.
      endloop.

      append |\| `{ to_lower( ls_method-name ) }` \| { visibility_text( ls_method-visibility ) } \| { lv_params } \||
             to lt_lines.
    endloop.

    rv_markdown = concat_lines_of( table = lt_lines
                                   sep   = cl_abap_char_utilities=>newline ).
  endmethod.


  method kind_text.
    rv_text = switch string( iv_parm_kind
                when cl_abap_objectdescr=>importing then `importing`
                when cl_abap_objectdescr=>exporting then `exporting`
                when cl_abap_objectdescr=>changing  then `changing`
                when cl_abap_objectdescr=>returning then `returning`
                else `param` ).
  endmethod.


  method visibility_text.
    rv_text = switch string( iv_visibility
                when cl_abap_objectdescr=>public    then `public`
                when cl_abap_objectdescr=>protected then `protected`
                when cl_abap_objectdescr=>private   then `private`
                else `?` ).
  endmethod.
endclass.
