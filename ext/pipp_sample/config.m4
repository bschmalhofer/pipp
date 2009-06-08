dnl $Id$
dnl config.m4 for extension pipp_sample

dnl Comments in this file start with the string 'dnl'.
dnl Remove where necessary. This file will not work
dnl without editing.

dnl If your extension references something external, use with:

dnl PHP_ARG_WITH(pipp_sample, for pipp_sample support,
dnl Make sure that the comment is aligned:
dnl [  --with-pipp_sample             Include pipp_sample support])

dnl Otherwise use enable:

PHP_ARG_ENABLE(pipp_sample, whether to enable pipp_sample support,
dnl Make sure that the comment is aligned:
[  --enable-pipp_sample           Enable pipp_sample support])

if test "$PHP_PIPP_SAMPLE" != "no"; then
  dnl Write more examples of tests here...

  dnl # --with-pipp_sample -> check with-path
  dnl SEARCH_PATH="/usr/local /usr"     # you might want to change this
  dnl SEARCH_FOR="/include/pipp_sample.h"  # you most likely want to change this
  dnl if test -r $PHP_PIPP_SAMPLE/$SEARCH_FOR; then # path given as parameter
  dnl   PIPP_SAMPLE_DIR=$PHP_PIPP_SAMPLE
  dnl else # search default path list
  dnl   AC_MSG_CHECKING([for pipp_sample files in default path])
  dnl   for i in $SEARCH_PATH ; do
  dnl     if test -r $i/$SEARCH_FOR; then
  dnl       PIPP_SAMPLE_DIR=$i
  dnl       AC_MSG_RESULT(found in $i)
  dnl     fi
  dnl   done
  dnl fi
  dnl
  dnl if test -z "$PIPP_SAMPLE_DIR"; then
  dnl   AC_MSG_RESULT([not found])
  dnl   AC_MSG_ERROR([Please reinstall the pipp_sample distribution])
  dnl fi

  dnl # --with-pipp_sample -> add include path
  dnl PHP_ADD_INCLUDE($PIPP_SAMPLE_DIR/include)

  dnl # --with-pipp_sample -> check for lib and symbol presence
  dnl LIBNAME=pipp_sample # you may want to change this
  dnl LIBSYMBOL=pipp_sample # you most likely want to change this 

  dnl PHP_CHECK_LIBRARY($LIBNAME,$LIBSYMBOL,
  dnl [
  dnl   PHP_ADD_LIBRARY_WITH_PATH($LIBNAME, $PIPP_SAMPLE_DIR/lib, PIPP_SAMPLE_SHARED_LIBADD)
  dnl   AC_DEFINE(HAVE_PIPP_SAMPLELIB,1,[ ])
  dnl ],[
  dnl   AC_MSG_ERROR([wrong pipp_sample lib version or lib not found])
  dnl ],[
  dnl   -L$PIPP_SAMPLE_DIR/lib -lm
  dnl ])
  dnl
  PHP_SUBST(PIPP_SAMPLE_SHARED_LIBADD)

  PHP_NEW_EXTENSION(pipp_sample, pipp_sample.c, $ext_shared)
fi
