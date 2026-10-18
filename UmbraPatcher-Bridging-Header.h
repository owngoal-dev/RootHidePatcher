//
//  UmbraPatcher-Bridging-Header.h
//  UmbraPatcher
//
//  Created by admin on 4/10/2023.
//

#ifndef UmbraPatcher_Bridging_Header_h
#define UmbraPatcher_Bridging_Header_h

#include <Foundation/Foundation.h>
#include "AppFileShare.h"

#if TARGET_IPHONE_SIMULATOR
#define ROOTHIDE_USE_STUB
#endif

#include "roothide.h"

#import <spawn.h>

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

#endif /* UmbraPatcher_Bridging_Header_h */
