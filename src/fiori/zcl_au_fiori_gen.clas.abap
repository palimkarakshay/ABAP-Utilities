class zcl_au_fiori_gen definition
  public
  final
  create public.

  public section.
    class-methods class_constructor.
    "! One field of the entity that becomes a Fiori app.
    types:
      begin of ty_field,
        name     type string,        " element / DB field name
        label    type string,        " UI label (defaults to the name)
        is_key   type abap_bool,      " part of the key?
        position type i,             " UI position (lineItem / identification)
      end of ty_field,
      tt_field type standard table of ty_field with default key.

    "! The generated source artifacts. Paste each into a new ADT object of the
    "! matching type, then activate (DDLS, BDEF, SRVD) and create a Service
    "! Binding + Launchpad tile (see service_binding for the steps).
    types:
      begin of ty_artifacts,
        interface_view     type string,   " ZI_*  DDLS  (root view on the table)
        projection_view    type string,   " ZC_*  DDLS  (UI projection, list report)
        behavior           type string,   " ZI_*  BDEF  (managed: create/update/delete)
        projection_behavior type string,  " ZC_*  BDEF  (projection)
        service_definition type string,   " ZUI_* SRVD
        service_binding    type string,   " how-to steps (binding is created in ADT)
      end of ty_artifacts.

    "! A value-help view plus the annotation that wires it to a consuming field.
    types:
      begin of ty_value_help,
        view       type string,   " ZI_VH_*  DDLS
        annotation type string,   " @Consumption.valueHelpDefinition to paste on the field
      end of ty_value_help.

    "! Derive a default field list from a DDIC table or structure via RTTI.
    "! The FIRST field is marked as key by default - review and adjust is_key for
    "! your real key fields before generating.
    class-methods fields_from_structure
      importing
        !iv_name         type string
      returning
        value(rt_fields) type tt_field
      raising
        zcx_au_error.

    "! Generate the CDS + RAP + service artifacts for a maintenance / list-report
    "! Fiori app over a persistent table.
    "!
    "! @parameter iv_entity        | logical entity name, e.g. `Product` (no prefix)
    "! @parameter iv_data_source   | the persistent DDIC table, e.g. `ztproduct`
    "! @parameter it_fields        | the fields to expose (see fields_from_structure)
    "! @parameter iv_namespace     | object name prefix, default `Z`
    "! @parameter iv_with_behavior | also generate RAP behavior (create/update/delete).
    "!                               Pass abap_false for a read-only list (e.g. an ALV
    "!                               report becomes a display-only Fiori list).
    class-methods generate
      importing
        !iv_entity        type string
        !iv_data_source   type string
        !it_fields        type tt_field
        !iv_namespace     type string default `Z`
        !iv_with_behavior type abap_bool default abap_true
      returning
        value(rs_result)  type ty_artifacts
      raising
        zcx_au_error.

    "! Generate a value-help (search-help replacement) CDS view, plus the
    "! @Consumption.valueHelpDefinition annotation to put on the consuming field.
    class-methods value_help
      importing
        !iv_entity       type string
        !iv_data_source  type string
        !iv_key_field    type string
        !iv_text_field   type string optional
        !iv_namespace    type string default `Z`
      returning
        value(rs_result) type ty_value_help
      raising
        zcx_au_error.

    "! Generate a metadata extension (DDLX) that holds the @UI annotations
    "! separately from the projection view (cleaner layering). Use this INSTEAD of
    "! the inline @UI in the generated projection.
    class-methods metadata_extension
      importing
        !iv_entity         type string
        !it_fields         type tt_field
        !iv_namespace      type string default `Z`
      returning
        value(rv_ddlx)     type string
      raising
        zcx_au_error.

  private section.
    " A CONSTANTS value must be a literal, so the newline is kept in class-data
    " and initialised once in the class constructor.
    class-data c_lf type abap_char1.


    class-methods join_lines
      importing
        !it_lines      type string_table
      returning
        value(rv_text) type string.
endclass.


class zcl_au_fiori_gen implementation.
  method class_constructor.
    c_lf = cl_abap_char_utilities=>newline.
  endmethod.


  method fields_from_structure.
    " RTTI: a DDIC table or structure name resolves to its line structure.
    cl_abap_typedescr=>describe_by_name(
      exporting
        p_name         = iv_name
      receiving
        p_descr_ref    = data(lo_descr)
      exceptions
        type_not_found = 1
        others         = 2 ).
    if sy-subrc <> 0 or lo_descr is not bound.
      zcx_au_error=>raise( |Table/structure { iv_name } not found| ) ##NO_TEXT.
    endif.

    data(lo_struct) = cast cl_abap_structdescr( lo_descr ).
    data(lv_position) = 10.
    loop at lo_struct->components into data(ls_component).
      append value #( name     = to_lower( ls_component-name )
                      label    = ls_component-name
                      " RTTI cannot tell us the key, so default the first field;
                      " the caller adjusts is_key for the real key fields.
                      is_key   = xsdbool( sy-tabix = 1 )
                      position = lv_position ) to rt_fields.
      lv_position = lv_position + 10.
    endloop.
  endmethod.


  method generate.
    if it_fields is initial.
      zcx_au_error=>raise( |No fields supplied for entity { iv_entity }| ) ##NO_TEXT.
    endif.

    data(lv_i_view) = |{ iv_namespace }I_{ iv_entity }|.   " interface view
    data(lv_c_view) = |{ iv_namespace }C_{ iv_entity }|.   " projection view
    data(lv_srvd)   = |{ iv_namespace }UI_{ iv_entity }|.  " service definition

    " ---- interface (root) view: ZI_* -----------------------------------------
    data lt_if type string_table.
    loop at it_fields into data(ls_field).
      append cond string( when ls_field-is_key = abap_true
                          then |  key { ls_field-name }|
                          else |      { ls_field-name }| ) to lt_if.
    endloop.
    rs_result-interface_view =
         |@AccessControl.authorizationCheck: #NOT_REQUIRED| && c_lf
      && |@EndUserText.label: '{ iv_entity } - interface view'| && c_lf
      && |define root view entity { lv_i_view }| && c_lf
      && |  as select from { iv_data_source }| && c_lf
      && |\{| && c_lf
      && concat_lines_of( table = lt_if sep = |,{ c_lf }| ) && c_lf
      && |\}|.

    " ---- projection view with UI annotations: ZC_* (List Report + Object Page)
    data lt_pr type string_table.
    loop at it_fields into ls_field.
      data lv_anno type string.
      if ls_field-is_key = abap_true.
        " one header facet, anchored on the (first) key field
        lv_anno = `      @UI.facet: [ { id: 'idMain', purpose: #STANDARD, ` &&
                  `type: #IDENTIFICATION_REFERENCE, label: '` && iv_entity && `', position: 10 } ]`.
        append lv_anno to lt_pr.
        append |  key { ls_field-name }| to lt_pr.
      else.
        lv_anno = `      @UI: { lineItem: [ { position: ` && |{ ls_field-position }| &&
                  ` } ], identification: [ { position: ` && |{ ls_field-position }| && ` } ] }`.
        append lv_anno to lt_pr.
        append |      { ls_field-name }| to lt_pr.
      endif.
    endloop.
    rs_result-projection_view =
         |@AccessControl.authorizationCheck: #NOT_REQUIRED| && c_lf
      && |@Metadata.allowExtensions: true| && c_lf
      && |@EndUserText.label: 'Manage { iv_entity }'| && c_lf
      && `@UI: { headerInfo: { typeName: '` && iv_entity && `', typeNamePlural: '` && iv_entity && `' } }` && c_lf
      && |define root view entity { lv_c_view }| && c_lf
      && |  as projection on { lv_i_view }| && c_lf
      && |\{| && c_lf
      && join_lines( lt_pr ) && c_lf
      && |\}|.

    " ---- behavior definitions (only for an editable app) ----------------------
    if iv_with_behavior = abap_true.
      " managed behavior: create / update / delete
      data lt_bd type string_table.
      append |managed;| to lt_bd.
      append |strict ( 2 );| to lt_bd.
      append || to lt_bd.
      append |define behavior for { lv_i_view } alias { iv_entity }| to lt_bd.
      append |persistent table { iv_data_source }| to lt_bd.
      append |lock master| to lt_bd.
      append |authorization master ( global )| to lt_bd.
      append |\{| to lt_bd.
      append |  create;| to lt_bd.
      append |  update;| to lt_bd.
      append |  delete;| to lt_bd.
      loop at it_fields into ls_field where is_key = abap_true.
        append |  field ( readonly ) { ls_field-name };| to lt_bd.
      endloop.
      append |\}| to lt_bd.
      rs_result-behavior = join_lines( lt_bd ).

      rs_result-projection_behavior =
           |projection;| && c_lf
        && |define behavior for { lv_c_view } alias { iv_entity }| && c_lf
        && |\{| && c_lf
        && |  use create;| && c_lf
        && |  use update;| && c_lf
        && |  use delete;| && c_lf
        && |\}|.
    endif.

    " ---- service definition ---------------------------------------------------
    rs_result-service_definition =
         |@EndUserText.label: 'Service for { iv_entity }'| && c_lf
      && |define service { lv_srvd }| && c_lf
      && |\{| && c_lf
      && |  expose { lv_c_view } as { iv_entity };| && c_lf
      && |\}|.

    " ---- service binding: created interactively in ADT ------------------------
    rs_result-service_binding =
         |Steps to finish the Fiori app:| && c_lf
      && |1. Create the 4 objects above (DDLS { lv_i_view }, DDLS { lv_c_view },| && c_lf
      && |   BDEF { lv_i_view }, BDEF { lv_c_view }, SRVD { lv_srvd }) and activate.| && c_lf
      && |2. Create a Service Binding for { lv_srvd }, type "OData V4 - UI", and Publish.| && c_lf
      && |3. Preview from the binding, or add a tile in the Fiori Launchpad / Launchpad| && c_lf
      && |   content (target mapping to the published OData service + SADL/UI app).| && c_lf
      && |4. Review keys, labels and @UI positions; add value helps / associations.|.
  endmethod.


  method value_help.
    if iv_key_field is initial.
      zcx_au_error=>raise( |A key field is required for the { iv_entity } value help| ) ##NO_TEXT.
    endif.

    data(lv_vh_view) = |{ iv_namespace }I_VH_{ iv_entity }|.

    data lt_vh type string_table.
    append |@AccessControl.authorizationCheck: #NOT_REQUIRED| to lt_vh.
    append |@Search.searchable: true| to lt_vh.
    append |@ObjectModel.resultSet.sizeCategory: #XS| to lt_vh.
    append |@EndUserText.label: '{ iv_entity } value help'| to lt_vh.
    append |define view entity { lv_vh_view }| to lt_vh.
    append |  as select from { iv_data_source }| to lt_vh.
    append |\{| to lt_vh.
    " a comma is only needed after the key when a text field follows
    append |  key { iv_key_field }| && cond string( when iv_text_field is not initial
                                                     then `,` ) to lt_vh.
    if iv_text_field is not initial.
      append |      { iv_text_field }| to lt_vh.
    endif.
    append |\}| to lt_vh.

    rs_result-view       = join_lines( lt_vh ).
    rs_result-annotation = `@Consumption.valueHelpDefinition: [ { entity: { name: '`
                        && lv_vh_view && `', element: '` && iv_key_field && `' } } ]`.
  endmethod.


  method metadata_extension.
    if it_fields is initial.
      zcx_au_error=>raise( |No fields for the metadata extension of { iv_entity }| ) ##NO_TEXT.
    endif.

    data(lv_c_view) = |{ iv_namespace }C_{ iv_entity }|.

    data lt_mx type string_table.
    append |@Metadata.layer: #CORE| to lt_mx.
    append |annotate entity { lv_c_view } with| to lt_mx.
    append |\{| to lt_mx.
    loop at it_fields into data(ls_field).
      append `  @UI.lineItem: [ { position: ` && |{ ls_field-position }| && ` } ]` to lt_mx.
      append `  @UI.identification: [ { position: ` && |{ ls_field-position }| && ` } ]` to lt_mx.
      append |  { ls_field-name };| to lt_mx.
    endloop.
    append |\}| to lt_mx.

    rv_ddlx = join_lines( lt_mx ).
  endmethod.


  method join_lines.
    rv_text = concat_lines_of( table = it_lines
                               sep   = c_lf ).
  endmethod.
endclass.
