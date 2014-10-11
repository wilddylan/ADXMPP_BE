//
//  ADXMPPConn.m
//  ADXMPP_BE
//
//  Created by Dylan on 14-10-8.
//  Copyright (c) 2014年 Dylan. All rights reserved.
//

#import "ADXMPPConn.h"
#import "ADMessageModel.h"
#import "ADCurrentTime.h"
#import <XMPPRosterMemoryStorage.h>

@interface ADXMPPConn ()

/*!
 *  @Author Dylan.
 *
 *  Call back Block
 */
@property (nonatomic, copy) connectSuccess connSuccess;
@property (nonatomic, copy) AuthenticateFailure authenFailure;

@property (nonatomic, copy) registerSuccess regisSuccess;
@property (nonatomic, copy) registerFailure regisFailure;

/*!
 *  call back block
 */
@property (nonatomic, copy) sendSuccess success;
@property (nonatomic, copy) sendFailure failure;

/*!
 *  call back block
 */
@property (nonatomic, copy) refreshRosterListFailure refreshFailure;
@property (nonatomic, copy) Rosterlist refreshSuccess;

/*!
 *  call back block
 */
@property (nonatomic, copy) userGoOnline rosterOnline;
@property (nonatomic, copy) userGoOffline rosterOffline;

/*!
 *  @Author Dylan.
 *
 *  XMPPRosterMemoryStorage
 */
@property (nonatomic, strong) XMPPRosterMemoryStorage * xmppRosterMemory;

@end

// shareInstance
static ADXMPPConn * xmppConn;

@implementation ADXMPPConn

#pragma mark shareInstance
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xmppConn = [[self alloc] init];
        
        [xmppConn initData];
        [xmppConn initRosterlist];
        [xmppConn initRoster];
    });
    
    return xmppConn;
}

#pragma mark - Methods
- (void)setupXmppStream {
    self.xmppStream = [[XMPPStream alloc] init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark on/off line
- (void)online {
    XMPPPresence * presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}

- (void)offline {
    XMPPPresence * presence = [XMPPPresence presenceWithType:@"unavailable"];
    [self.xmppStream sendElement:presence];
    [self.xmppStream disconnect];
}

#pragma mark connection
- (BOOL)connectionWithUserName:(NSString *)userName passWord:(NSString *)passWord success:(connectSuccess)Success failure:(AuthenticateFailure)Failure {
    
    // setup xmppStream
    [self setupXmppStream];
    
    // get username, password
    self.userName = userName;
    self.passWord = passWord;
    
    // set callback block
    self.connSuccess = Success;
    self.authenFailure = Failure;
    
    if ([self.xmppStream isConnected]) {
        return YES;
    }
    
    if (userName == nil) {
        return NO;
    }
    
    // setJID
    [self.xmppStream setMyJID:[XMPPJID jidWithString:userName]];
    [self.xmppStream setHostName:SERVER];
    
    NSError * error = nil;
    if (![self.xmppStream connectWithTimeout:30 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        Failure(error);
        return NO;
    }
    
    return YES;
}

- (void)registerWithUserName:(NSString *)userName passWord:(NSString *)passWord success:(registerSuccess)Success failure:(registerFailure)Failure {
    
    // set user type
    self.USERTYPE = REGISTER;
    
    // set username, password
    self.userName = [userName stringByAppendingString:DOMAINS];
    self.passWord = passWord;
    
    self.regisSuccess = Success;
    self.regisFailure = Failure;
    
    [self connectionWithUserName:self.userName passWord:passWord success:Success failure:Failure];
}

#pragma mark - delegateMethods
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSError * error = nil;
    
    // kind of user type
    if (self.USERTYPE == REGISTER) {
        
        // registe
        [self.xmppStream setMyJID:[XMPPJID jidWithString:self.userName]];
        NSError * error = nil;
        if (![self.xmppStream registerWithPassword:self.passWord error:&error]) {
            self.regisFailure([error localizedDescription]);
        }
    } else {
        // authenticate
        [self.xmppStream authenticateWithPassword:self.passWord error:&error];
        if (error != nil) {
            self.authenFailure([error localizedDescription]);
        }
    }
}

// dis connect
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"%@", [error localizedDescription]);
}

// authenticate
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    if (self.authenFailure != nil) {
        self.authenFailure(error);
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    // online
    [self online];
    if (self.connSuccess != nil) {
        self.connSuccess();
    }
}

// regist
- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    
    if (self.regisSuccess != nil) {
        self.regisSuccess();
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error {
    if (self.regisFailure != nil) {        
        self.regisFailure(error);
    }
}

#pragma mark - initData
- (void)initData {
    // data save
    self.unReadMsg = [NSMutableDictionary dictionary];
}

#pragma mark Methods
- (void)sendMessage: (ADMessageModel *)message
        sendSuccess: (sendSuccess)success
        sendFailure: (sendFailure)failure {
    
    // set callback block
    self.success = success;
    self.failure = failure;
    
    NSXMLElement * body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message.body];
    
    //生成XML消息文档
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    //消息类型
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    //发送给谁
    [mes addAttributeWithName:@"to" stringValue:message.to];
    //由谁发送
    [mes addAttributeWithName:@"from" stringValue:message.from];
    //组合
    [mes addChild:body];
    //发送消息
    [[self xmppStream] sendElement:mes];
}

#pragma mark newMsg
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    
    NSString * body = [[message elementForName:@"body"] stringValue];
    NSString * from = [[message attributeForName:@"from"] stringValue];
    
    if (body != nil) {
        
        NSMutableDictionary * msgDict = [NSMutableDictionary dictionary];
        ADMessageModel * model = [[ADMessageModel alloc] init];
        model.body = body;
        model.from = from;
        [msgDict setValue:model forKey:[ADCurrentTime getCurrentTime]];
        
        if ([from isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:CURRENT_CHAT]]) {
            
            if (self.newMessage != nil) {
                self.newMessage(msgDict);
            }
        } else {
            // not current chat
            if ([_unReadMsg.allKeys containsObject:from]) {
                [_unReadMsg[from] addObject:model];
            } else {
                [_unReadMsg setValue:[NSMutableArray arrayWithObject:msgDict] forKey:from];
            }
        }
    }
}

#pragma mark - rosterList

- (void)initRosterlist {
    self.rosterDict = [NSMutableDictionary dictionary];
}

- (void)refreshRosterList: (Rosterlist)success
                  failure: (refreshRosterListFailure)failure {
    
    // call back
    self.refreshSuccess = success;
    self.refreshFailure = failure;
    
    NSXMLElement * query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
    
    XMPPJID * myJID = self.xmppStream.myJID;
    [iq addAttributeWithName:@"from" stringValue:myJID.description];
    [iq addAttributeWithName:@"to" stringValue:myJID.domain];
    [iq addAttributeWithName:@"id" stringValue:@"123456"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:query];
    
    [self.xmppStream sendElement:iq];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error {
    
    if (self.refreshFailure != nil) {
        self.refreshFailure(error);
    }
}

// get user list
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
    
    // kind of result
    if ([@"result" isEqualToString:iq.type]) {
        NSXMLElement * query = iq.childElement;
        
        if ([@"query" isEqualToString:query.name]) {
            NSArray * items = [query children];
            for (NSXMLElement * item in items) {
                NSString * jid = [item attributeStringValueForName:@"jid"];
                XMPPJID * xmppJID = [XMPPJID jidWithString:jid];
                [_rosterDict setValue:xmppJID forKey:jid];
            }
        }
        // block
            self.refreshSuccess(_rosterDict);
        
        return YES;
    }
    
    NSLog(@"get iq error");
    return NO;
}

#pragma mark presence
- (void)refreshRosterPresence: (userGoOnline)online
                      offline: (userGoOffline)offline {
    
    self.rosterOnline = online;
    self.rosterOffline = offline;
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    
    // get presence type
    NSString * presenceType = [presence type];
    NSString * userID = [[sender myJID] user];
    
    NSString * presencrFromUser = [[presence from] user];
    if (![presencrFromUser isEqualToString:userID]) {
        if ([presenceType isEqualToString:@"available"]) {
                self.rosterOnline(presencrFromUser);
        } else if ([presenceType isEqualToString:@"unavailable"]) {
                self.rosterOffline(presencrFromUser);
        }
    }
}

#pragma mark - rosterHandle

// initRoster
- (void)initRoster {
    self.xmppRosterMemory = [[XMPPRosterMemoryStorage alloc] init];
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterMemory];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoster activate:self.xmppStream];
}

- (void)addFriend: (NSString *)accountName {
    [_xmppRoster addUser:[XMPPJID jidWithString:[accountName stringByAppendingString:DOMAINS]] withNickname:nil];
}

- (void)removeFriend: (NSString *)accountName {
    [_xmppRoster removeUser:[XMPPJID jidWithString:[accountName stringByAppendingString:DOMAINS]]];
}

// call back
- (void)dealWithFriendAsk: (BOOL)isAgree
              accountName: (NSString *)accountName {
    XMPPJID * jid=[XMPPJID jidWithString:[NSString stringWithFormat:@"%@%@",accountName,DOMAINS]];
    if(isAgree){
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:NO];
    }else{
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
    }

}

#pragma mark addFriendDelegateMethods
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    
    NSString *presenceFromUser =[NSString stringWithFormat:@"%@", [[presence from] user]];
    if (self.acceptOrDenyFriend != nil) {
        BOOL isAgree = self.acceptOrDenyFriend(presenceFromUser);
        [self dealWithFriendAsk:isAgree accountName:presenceFromUser];
    }
}

@end
