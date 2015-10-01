//
//  Chromium Coda.h
//  Chromium Coda
//
//  Created by Ahmed Hussein on 9/22/15.
//  Copyright (c) 2015 Ahmed Hussein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodaPluginsController.h"

@class CodaPlugInsController;


@interface ChromiumCoda : NSObject <CodaPlugIn>
{
    CodaPlugInsController* controller;
}

@end
