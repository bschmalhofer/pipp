/*
  +----------------------------------------------------------------------+
  | PHP Version 5                                                        |
  +----------------------------------------------------------------------+
  | Copyright (c) 1997-2008 The PHP Group                                |
  +----------------------------------------------------------------------+
  | This source file is subject to version 3.01 of the PHP license,      |
  | that is bundled with this package in the file LICENSE, and is        |
  | available through the world-wide-web at the following url:           |
  | http://www.php.net/license/3_01.txt                                  |
  | If you did not receive a copy of the PHP license and are unable to   |
  | obtain it through the world-wide-web, please send a note to          |
  | license@php.net so we can mail you a copy immediately.               |
  +----------------------------------------------------------------------+
  | Author:                                                              |
  +----------------------------------------------------------------------+
*/

/* $Id: header,v 1.16.2.1.2.1.2.1 2008/02/07 19:39:50 iliaa Exp $ */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
#include "php_pipp_sample.h"

/* If you declare any globals in php_pipp_sample.h uncomment this:
ZEND_DECLARE_MODULE_GLOBALS(pipp_sample)
*/

/* True global resources - no need for thread safety here */
static int le_pipp_sample;

/* {{{ pipp_sample_functions[]
 *
 * Every user visible function must have an entry in pipp_sample_functions[].
 */
const zend_function_entry pipp_sample_functions[] = {
	PHP_FE(confirm_pipp_sample_compiled,	NULL)		/* For testing, remove later. */
	{NULL, NULL, NULL}	/* Must be the last line in pipp_sample_functions[] */
};
/* }}} */

/* {{{ pipp_sample_module_entry
 */
zend_module_entry pipp_sample_module_entry = {
#if ZEND_MODULE_API_NO >= 20010901
	STANDARD_MODULE_HEADER,
#endif
	"pipp_sample",
	pipp_sample_functions,
	PHP_MINIT(pipp_sample),
	PHP_MSHUTDOWN(pipp_sample),
	PHP_RINIT(pipp_sample),		/* Replace with NULL if there's nothing to do at request start */
	PHP_RSHUTDOWN(pipp_sample),	/* Replace with NULL if there's nothing to do at request end */
	PHP_MINFO(pipp_sample),
#if ZEND_MODULE_API_NO >= 20010901
	"0.1", /* Replace with version number for your extension */
#endif
	STANDARD_MODULE_PROPERTIES
};
/* }}} */

#ifdef COMPILE_DL_PIPP_SAMPLE
ZEND_GET_MODULE(pipp_sample)
#endif

/* {{{ PHP_INI
 */
/* Remove comments and fill if you need to have entries in php.ini
PHP_INI_BEGIN()
    STD_PHP_INI_ENTRY("pipp_sample.global_value",      "42", PHP_INI_ALL, OnUpdateLong, global_value, zend_pipp_sample_globals, pipp_sample_globals)
    STD_PHP_INI_ENTRY("pipp_sample.global_string", "foobar", PHP_INI_ALL, OnUpdateString, global_string, zend_pipp_sample_globals, pipp_sample_globals)
PHP_INI_END()
*/
/* }}} */

/* {{{ php_pipp_sample_init_globals
 */
/* Uncomment this function if you have INI entries
static void php_pipp_sample_init_globals(zend_pipp_sample_globals *pipp_sample_globals)
{
	pipp_sample_globals->global_value = 0;
	pipp_sample_globals->global_string = NULL;
}
*/
/* }}} */

/* {{{ PHP_MINIT_FUNCTION
 */
PHP_MINIT_FUNCTION(pipp_sample)
{
	/* If you have INI entries, uncomment these lines 
	REGISTER_INI_ENTRIES();
	*/
	return SUCCESS;
}
/* }}} */

/* {{{ PHP_MSHUTDOWN_FUNCTION
 */
PHP_MSHUTDOWN_FUNCTION(pipp_sample)
{
	/* uncomment this line if you have INI entries
	UNREGISTER_INI_ENTRIES();
	*/
	return SUCCESS;
}
/* }}} */

/* Remove if there's nothing to do at request start */
/* {{{ PHP_RINIT_FUNCTION
 */
PHP_RINIT_FUNCTION(pipp_sample)
{
	return SUCCESS;
}
/* }}} */

/* Remove if there's nothing to do at request end */
/* {{{ PHP_RSHUTDOWN_FUNCTION
 */
PHP_RSHUTDOWN_FUNCTION(pipp_sample)
{
	return SUCCESS;
}
/* }}} */

/* {{{ PHP_MINFO_FUNCTION
 */
PHP_MINFO_FUNCTION(pipp_sample)
{
	php_info_print_table_start();
	php_info_print_table_header(2, "pipp_sample support", "enabled");
	php_info_print_table_end();

	/* Remove comments if you have entries in php.ini
	DISPLAY_INI_ENTRIES();
	*/
}
/* }}} */


/* Remove the following function when you have succesfully modified config.m4
   so that your module can be compiled into PHP, it exists only for testing
   purposes. */

/* Every user-visible function in PHP should document itself in the source */
/* {{{ proto string confirm_pipp_sample_compiled(string arg)
   Return a string to confirm that the module is compiled in */
PHP_FUNCTION(confirm_pipp_sample_compiled)
{
	char *arg = NULL;
	int arg_len, len;
	char *strg;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &arg, &arg_len) == FAILURE) {
		return;
	}

	len = spprintf(&strg, 0, "Congratulations! You have successfully modified ext/%.78s/config.m4. Module %.78s is now compiled into PHP.", "pipp_sample", arg);
	RETURN_STRINGL(strg, len, 0);
}
/* }}} */
/* The previous line is meant for vim and emacs, so it can correctly fold and 
   unfold functions in source code. See the corresponding marks just before 
   function definition, where the functions purpose is also documented. Please 
   follow this convention for the convenience of others editing your code.
*/


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
