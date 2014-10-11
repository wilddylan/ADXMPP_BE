ADXMPP_BE
=========

ADXMPP_HANDLE
//
//  ADXMPPConn.h
//  ADXMPP_BE
//
//  Created by Dylan on 14-10-8.
//  Copyright (c) 2014年 Dylan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPP.h>
#import <XMPPRoster.h>

@class ADMessageModel;

/**
 * kind of user type
 */
typedef enum {
    LOGIN,
    REGISTER
}USER_TYPE;

/*!
 *  user presence
 */
typedef enum {
    AVAILABLE,
    UNAVAILABLE
}USER_PRESENCE;

/*!
 *  @Author Dylan.
 *
 *  Callbacl Block
 */
typedef void(^connectSuccess)();
typedef void(^AuthenticateFailure)(id);

typedef void(^registerSuccess)();
typedef void(^registerFailure)(id);

@interface ADXMPPConn : NSObject <XMPPStreamDelegate, XMPPRosterDelegate>

/*!
 *  @Author Dylan.
 *
 *  xmppStream
 */
@property (nonatomic, strong) XMPPStream * xmppStream;

/*!
 *  @Author Dylan.
 *
 *  Username, Password
 */
@property (nonatomic, strong) NSString * userName;
@property (nonatomic, strong) NSString * passWord;

/*!
 *  @Author Dylan. UserType
 */
@property (nonatomic) USER_TYPE USERTYPE;

/*!
 *  @Author Dylan.
 *
 *  Methods
 */
#pragma mark - Methods

/*!
 *  shareInstance
 */
+ (instancetype)shareInstance;

/*!
 *  setup xmppStream
 */
- (void) setupXmppStream;

/*!
 *  on/off line
 */
- (void) online;
- (void) offline;

/*!
 *  connection/register
 */
- (BOOL)connectionWithUserName: (NSString *)userName
                      passWord: (NSString *)passWord
                       success: (connectSuccess)Success
                       failure: (AuthenticateFailure)Failure;

- (void)registerWithUserName: (NSString *)userName
                    passWord: (NSString *)passWord
                     success: (registerSuccess)Success
                     failure: (registerFailure)Failure;

/*!
 *  @Author Dylan.
 *
 *  callback Block
 */
typedef void(^sendSuccess)();
typedef void(^sendFailure)(id);

/*!
 *  sendMessageBy model
 */
- (void)sendMessage: (ADMessageModel *)message
        sendSuccess: (sendSuccess)success
        sendFailure: (sendFailure)failure;

/*!
 *  @Author Dylan.
 *
 *  unRead Msg
 */
@property (nonatomic, strong) NSMutableDictionary * unReadMsg;

/*!
 *  @Author Dylan.
 *
 *  new Msg
 */
@property (nonatomic, copy) void (^newMessage) (id);


/*!
 *  @Author Dylan.
 *
 *  Roster
 */

typedef void (^refreshRosterListFailure) (id);
typedef void (^Rosterlist) (id);

/*!
 *  @Author Dylan.
 *
 *  request for roster list. IQ
 */
- (void)refreshRosterList: (Rosterlist)success
                  failure: (refreshRosterListFailure)failure;
@property (nonatomic, strong) NSMutableDictionary * rosterDict;

/*!
 *  @Author Dylan.
 *
 *  Paresence
 */
typedef void (^userGoOnline) (NSString *);
typedef void (^userGoOffline) (NSString *);

- (void)refreshRosterPresence: (userGoOnline)online
                      offline: (userGoOffline)offline;

/*!
 *  @Author Dylan.
 *
 *  addRoster.
 */
// if you want to deny or add friend. please call this block
@property (nonatomic, copy) BOOL (^acceptOrDenyFriend) (NSString *);
@property (nonatomic, strong) XMPPRoster * xmppRoster;

/*!
 *  @Author Dylan. Methods
 */
- (void)addFriend: (NSString *)accountName;
- (void)removeFriend: (NSString *)accountName;

@end
