class zcl_au_dataset definition
  public
  final
  create public.

  public section.
    "! Read a UTF-8 text file from the application server as one string.
    class-methods read_text
      importing
        !iv_path       type string
      returning
        value(rv_text) type string
      raising
        zcx_au_error.

    "! Write a string to a UTF-8 text file on the application server (overwrites).
    "! Lines are split at newline and written as records.
    class-methods write_text
      importing
        !iv_path     type string
        !iv_content  type string
      raising
        zcx_au_error.

    "! Read a binary file from the application server.
    class-methods read_binary
      importing
        !iv_path       type string
      returning
        value(rv_data) type xstring
      raising
        zcx_au_error.

    "! Write raw bytes to a binary file on the application server (overwrites).
    class-methods write_binary
      importing
        !iv_path    type string
        !iv_content type xstring
      raising
        zcx_au_error.

    class-methods delete
      importing
        !iv_path type string
      raising
        zcx_au_error.

    "! True if the path can be opened for input.
    class-methods exists
      importing
        !iv_path         type string
      returning
        value(rv_exists) type abap_bool.
endclass.


class zcl_au_dataset implementation.
  method read_text.
    open dataset iv_path for input in text mode encoding utf-8 with smart linefeed.
    if sy-subrc <> 0.
      zcx_au_error=>raise( |Cannot open { iv_path } for input (rc={ sy-subrc })| ) ##NO_TEXT.
    endif.

    data lv_line type string.
    data lt_lines type string_table.
    do.
      read dataset iv_path into lv_line.
      if sy-subrc <> 0.
        exit.
      endif.
      append lv_line to lt_lines.
    enddo.
    close dataset iv_path.

    rv_text = concat_lines_of( table = lt_lines
                               sep   = cl_abap_char_utilities=>newline ).
  endmethod.


  method write_text.
    open dataset iv_path for output in text mode encoding utf-8 with smart linefeed.
    if sy-subrc <> 0.
      zcx_au_error=>raise( |Cannot open { iv_path } for output (rc={ sy-subrc })| ) ##NO_TEXT.
    endif.

    split iv_content at cl_abap_char_utilities=>newline into table data(lt_lines).
    loop at lt_lines into data(lv_line).
      transfer lv_line to iv_path.
    endloop.
    close dataset iv_path.
  endmethod.


  method read_binary.
    open dataset iv_path for input in binary mode.
    if sy-subrc <> 0.
      zcx_au_error=>raise( |Cannot open { iv_path } for input (rc={ sy-subrc })| ) ##NO_TEXT.
    endif.

    data lv_chunk type xstring.
    data lv_len   type i.
    do.
      read dataset iv_path into lv_chunk maximum length 8192 actual length lv_len.
      if lv_len > 0.
        concatenate rv_data lv_chunk(lv_len) into rv_data in byte mode.
      endif.
      if sy-subrc <> 0.
        exit.
      endif.
    enddo.
    close dataset iv_path.
  endmethod.


  method write_binary.
    open dataset iv_path for output in binary mode.
    if sy-subrc <> 0.
      zcx_au_error=>raise( |Cannot open { iv_path } for output (rc={ sy-subrc })| ) ##NO_TEXT.
    endif.
    transfer iv_content to iv_path.
    close dataset iv_path.
  endmethod.


  method delete.
    delete dataset iv_path.
    if sy-subrc <> 0.
      zcx_au_error=>raise( |Cannot delete { iv_path } (rc={ sy-subrc })| ) ##NO_TEXT.
    endif.
  endmethod.


  method exists.
    open dataset iv_path for input in binary mode.
    if sy-subrc = 0.
      rv_exists = abap_true.
      close dataset iv_path.
    endif.
  endmethod.
endclass.
