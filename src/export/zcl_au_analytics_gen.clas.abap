class zcl_au_analytics_gen definition
  public
  final
  create public.

  public section.
    class-methods class_constructor.
    "! One field of the exported entity. Mark measures (numeric values to be
    "! aggregated) with is_measure; everything else is a dimension/key.
    types:
      begin of ty_field,
        name       type string,
        is_key     type abap_bool,
        is_measure type abap_bool,
      end of ty_field,
      tt_field type standard table of ty_field with default key.

    "! Artifacts that expose data over OData for an external consumer
    "! (Power BI, Excel, Tableau, custom connectors, ...).
    types:
      begin of ty_export,
        cds_view           type string,   " ZC_*  consumption view
        service_definition type string,   " ZAPI_* SRVD (bind as OData V2/V4)
        connect_steps      type string,   " how to bind + connect Power BI / external
      end of ty_export.

    "! Generate a consumption CDS view + service definition to expose a table/view
    "! as OData for external BI tools (Power BI's "OData feed" connector, etc.).
    class-methods odata_export
      importing
        !iv_entity       type string
        !iv_data_source  type string
        !it_fields       type tt_field
        !iv_namespace    type string default `Z`
      returning
        value(rs_result) type ty_export
      raising
        zcx_au_error.

    "! Generate an analytical CUBE CDS view (dimensions + aggregated measures) for
    "! live analytics (consumed via OData/InA, e.g. an Analytical List Page or a
    "! Power BI report over the analytical OData service).
    class-methods analytics_cube
      importing
        !iv_entity      type string
        !iv_data_source type string
        !it_fields      type tt_field
        !iv_namespace   type string default `Z`
      returning
        value(rv_view)  type string
      raising
        zcx_au_error.

    "! Generate a data-extraction-enabled CDS view (for replication/CDC into SAP
    "! Datasphere, BW, or an external warehouse via the extraction frameworks).
    class-methods extraction_view
      importing
        !iv_entity      type string
        !iv_data_source type string
        !it_fields      type tt_field
        !iv_namespace   type string default `Z`
      returning
        value(rv_view)  type string
      raising
        zcx_au_error.

  private section.
    class-data c_lf type abap_char1.

    "! Render the field lines of a SELECT list (key prefix + optional per-field
    "! annotation passed by the caller is added separately).
    class-methods field_lines
      importing
        !it_fields     type tt_field
      returning
        value(rt_lines) type string_table.
endclass.


class zcl_au_analytics_gen implementation.
  method class_constructor.
    c_lf = cl_abap_char_utilities=>newline.
  endmethod.


  method field_lines.
    loop at it_fields into data(ls_field).
      rt_lines = value #( base rt_lines
                          ( cond string( when ls_field-is_key = abap_true
                                         then |  key { ls_field-name }|
                                         else |      { ls_field-name }| ) ) ).
    endloop.
  endmethod.


  method odata_export.
    if it_fields is initial.
      zcx_au_error=>raise( |No fields supplied for { iv_entity }| ) ##NO_TEXT.
    endif.

    data(lv_view) = |{ iv_namespace }C_{ iv_entity }|.
    data(lv_srvd) = |{ iv_namespace }API_{ iv_entity }|.

    rs_result-cds_view =
         |@AccessControl.authorizationCheck: #CHECK| && c_lf
      && |@EndUserText.label: '{ iv_entity } - OData export'| && c_lf
      && |define root view entity { lv_view }| && c_lf
      && |  as select from { iv_data_source }| && c_lf
      && |\{| && c_lf
      && concat_lines_of( table = field_lines( it_fields ) sep = |,{ c_lf }| ) && c_lf
      && |\}|.

    rs_result-service_definition =
         |@EndUserText.label: 'OData service for { iv_entity }'| && c_lf
      && |define service { lv_srvd }| && c_lf
      && |\{| && c_lf
      && |  expose { lv_view } as { iv_entity };| && c_lf
      && |\}|.

    rs_result-connect_steps =
         |Expose & consume in Power BI / external tools:| && c_lf
      && |1. Activate DDLS { lv_view } and SRVD { lv_srvd }.| && c_lf
      && |2. Create a Service Binding for { lv_srvd } - type "OData V2 - Web API"| && c_lf
      && |   (Power BI's OData connector works best with V2; V4 also supported).| && c_lf
      && |3. Publish; copy the service URL from the binding (the $metadata URL).| && c_lf
      && |4. Power BI Desktop: Get Data -> OData feed -> paste the URL ->| && c_lf
      && |   authenticate (Basic / OAuth / SAP principal propagation) -> Load.| && c_lf
      && |5. Push filtering to the server with URL options ($filter, $select, $top)| && c_lf
      && |   or model parameters to keep extracts small.| && c_lf
      && |Alternative quick path (classic DEFINE VIEW only): annotate with| && c_lf
      && |@OData.publish: true to auto-generate a V2 service (activate in| && c_lf
      && |/IWFND/MAINT_SERVICE on-premise).|.
  endmethod.


  method analytics_cube.
    if it_fields is initial.
      zcx_au_error=>raise( |No fields supplied for { iv_entity }| ) ##NO_TEXT.
    endif.

    data lt_lines type string_table.
    loop at it_fields into data(ls_field).
      if ls_field-is_measure = abap_true.
        " measures are aggregated; default to SUM (adjust as needed)
        append `      @DefaultAggregation: #SUM` to lt_lines.
        append |      { ls_field-name }| to lt_lines.
      else.
        append cond string( when ls_field-is_key = abap_true
                            then |  key { ls_field-name }|
                            else |      { ls_field-name }| ) to lt_lines.
      endif.
    endloop.

    rv_view =
         |@Analytics.dataCategory: #CUBE| && c_lf
      && |@AccessControl.authorizationCheck: #CHECK| && c_lf
      && |@EndUserText.label: '{ iv_entity } - analytics cube'| && c_lf
      && |define view entity { iv_namespace }C_{ iv_entity }_CUBE| && c_lf
      && |  as select from { iv_data_source }| && c_lf
      && |\{| && c_lf
      && concat_lines_of( table = lt_lines sep = |,{ c_lf }| ) && c_lf
      && |\}|.
  endmethod.


  method extraction_view.
    if it_fields is initial.
      zcx_au_error=>raise( |No fields supplied for { iv_entity }| ) ##NO_TEXT.
    endif.

    rv_view =
         |@AccessControl.authorizationCheck: #NOT_REQUIRED| && c_lf
      && |@Analytics.dataExtraction.enabled: true| && c_lf
      && |// delta needs a CDC-capable source; see @Analytics.dataExtraction.delta.*| && c_lf
      && |@EndUserText.label: '{ iv_entity } - extraction'| && c_lf
      && |define view entity { iv_namespace }C_{ iv_entity }_EXTR| && c_lf
      && |  as select from { iv_data_source }| && c_lf
      && |\{| && c_lf
      && concat_lines_of( table = field_lines( it_fields ) sep = |,{ c_lf }| ) && c_lf
      && |\}|.
  endmethod.
endclass.
