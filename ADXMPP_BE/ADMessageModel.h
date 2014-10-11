//
//  ADMessageModel.h
//  ADXMPP_BE
//
//  Created by Dylan on 14-10-8.
//  Copyright (c) 2014年 Dylan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADMessageModel : NSObject

/*!
 *  @Author Dylan.
 *
 *  Message.Model
 */
@property (nonatomic, strong) NSString * from;
@property (nonatomic, strong) NSString * to;
@property (nonatomic, strong) NSString * body;
@property (nonatomic, strong) NSDate * date;

@end
