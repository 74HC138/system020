#ifndef _PROTO_LAYOUT_H
#define _PROTO_LAYOUT_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif
#if !defined(CLIB_LAYOUT_PROTOS_H) && !defined(__GNUC__)
#include <clib/layout_protos.h>
#endif

#ifndef __NOLIBBASE__
extern struct Library *LayoutBase;
#endif

#ifdef __GNUC__
#ifdef __AROS__
#include <defines/layout.h>
#else
#include <inline/layout.h>
#endif
#elif !defined(__VBCC__)
#include <pragma/layout_lib.h>
#endif

#endif	/*  _PROTO_LAYOUT_H  */
