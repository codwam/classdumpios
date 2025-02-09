// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "ULEB128.h"

uint64_t read_uleb128(const uint8_t **ptrptr, const uint8_t *end)
{
    const uint8_t *ptr = *ptrptr;
    uint64_t result = 0;
    int bit = 0;
    
    //DLog(@"read_uleb128()");
    do {
        NSCAssert(ptr != end, @"Malformed uleb128", nil);
        
        //DLog(@"byte: %02x", *ptr);
        uint64_t slice = *ptr & 0x7f;
        
        if (bit >= 64 || slice << bit >> bit != slice) {
            DLog(@"uleb128 too big");
            exit(88);
        } else {
            result |= (slice << bit);
            bit += 7;
        }
    }
    while ((*ptr++ & 0x80) != 0);
    
#if 0
    static NSUInteger maxlen = 0;
    if (maxlen < ptr - *ptrptr) {
        const uint8_t *ptr2 = *ptrptr;
        
        NSMutableArray *byteStrs = [NSMutableArray array];
        do {
            [byteStrs addObject:[NSString stringWithFormat:@"%02x", *ptr2]];
        } while (++ptr2 < ptr);
        //DLog(@"max uleb length now: %u (%@)", ptr - *ptrptr, [byteStrs componentsJoinedByString:@" "]);
        //DLog(@"sizeof(uint64_t): %u, sizeof(uintptr_t): %u", sizeof(uint64_t), sizeof(uintptr_t));
        maxlen = ptr - *ptrptr;
    }
#endif
    
    *ptrptr = ptr;
    return result;
}

int64_t read_sleb128(const uint8_t **ptrptr, const uint8_t *end)
{
    const uint8_t *ptr = *ptrptr;
    
    int64_t result = 0;
    int bit = 0;
    uint8_t byte;
    
    //DLog(@"read_sleb128()");
    do {
        NSCAssert(ptr != end, @"Malformed sleb128", nil);
        
        byte = *ptr++;
        //DLog(@"%02x", byte);
        result |= ((byte & 0x7f) << bit);
        bit += 7;
    } while ((byte & 0x80) != 0);
    
    //DLog(@"result before sign extend: %ld", result);
    // sign extend negative numbers
    // This essentially clears out from -1 the low order bits we've already set, and combines that with our bits.
    if ( (byte & 0x40) != 0 )
        result |= (-1LL) << bit;
    
    //DLog(@"result after sign extend: %ld", result);
    
    //DLog(@"ptr before: %p, after: %p", *ptrptr, ptr);
    *ptrptr = ptr;
    return result;
}
