/*
 * Copyright (c) 1998-2006 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#include <IOKit/IOService.h>

#ifndef _IOKIT_IOHIDUSERCLIENTINITER_H
#define _IOKIT_IOHIDUSERCLIENTINITER_H
class IOHIDUserClientIniter : public IOService 
{
    OSDeclareDefaultStructors(IOHIDUserClientIniter);

protected:
    struct ExpansionData { };
    
    /*! @var reserved
        Reserved for future use.  (Internal use only)  */
    ExpansionData *reserved;

    virtual bool 		mergeDictionaryIntoProvider(IOService *  provider, OSDictionary *  mergeDict);
    virtual bool		mergeDictionaryIntoDictionary(OSDictionary *  sourceDictionary,  OSDictionary *  targetDictionary);

public:
    
    virtual bool		start(IOService *  provider) ;

/*
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 0);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 1);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 2);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 3);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 4);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 5);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 6);
    OSMetaClassDeclareReservedUnused(IOHIDUserClientIniter, 7);
*/
};

#endif /* ! _IOKIT_IOHIDUSERCLIENTINITER_H */
