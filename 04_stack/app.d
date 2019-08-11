void main()
{
    import parser : parser_print_all;
    import cl_getc : cl_getc_set_src;
    cl_getc_set_src("123 45 add /some { 2 3 add } def");
    parser_print_all();
}
