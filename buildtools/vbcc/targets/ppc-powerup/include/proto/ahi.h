#ifndef _PROTO_AHI_H
#define _PROTO_AHI_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif
#if !defined(CLIB_AHI_PROTOS_H) && !defined(__GNUC__)
#include <clib/ahi_protos.h>
#endif

#ifndef __NOLIBBASE__
extern struct Library *AHIBase;
#endif

#ifdef __GNUC__
#ifdef __AROS__
#include <defines/ahi.h>
#else
#include <inline/ahi.h>
#endif
#elif !defined(__VBCC__)
#include <pragma/ahi_lib.h>
#endif

#endif	/*  _PROTO_AHI_H  */
