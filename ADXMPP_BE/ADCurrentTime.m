//
//  ADCurrentTime.m
//  ADXMPP_BE
//
//  Created by Dylan on 14-10-8.
//  Copyright (c) 2014年 Dylan. All rights reserved.
//

#import "ADCurrentTime.h"

@implementation ADCurrentTime

+(NSString *)getCurrentTime{
    
    NSDate *nowUTC = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    return [dateFormatter stringFromDate:nowUTC];
    
}

@end
