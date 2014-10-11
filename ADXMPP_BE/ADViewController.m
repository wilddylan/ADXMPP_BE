//
//  ADViewController.m
//  ADXMPP_BE
//
//  Created by Dylan on 14-10-8.
//  Copyright (c) 2014年 Dylan. All rights reserved.
//

#import "ADViewController.h"
#import "ADMessageModel.h"

@interface ADViewController ()

@end

@implementation ADViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // testLogin
    [XMPPHANDLE connectionWithUserName:@"dylan@127.0.0.1" passWord:@"admin" success:^{
        NSLog(@"success");
        
        [XMPPHANDLE refreshRosterPresence:^(NSString * userID) {
            
            NSLog(@"%@%@", userID, DOMAINS);
        } offline:^(NSString * userID) {
            
            NSLog(@"%@%@", userID, DOMAINS);
        }];
        
        [XMPPHANDLE refreshRosterList:^(id dict) {
            NSLog(@"%@", dict);
            
        } failure:^(id error) {
            NSLog(@"%@", error);
        }];
        
        // testMsg
        [[NSUserDefaults standardUserDefaults] setValue:@"alice@127.0.0.1/xueyulundeMacBook-Pro" forKey:CURRENT_CHAT];
        [XMPPHANDLE setNewMessage:^(id dict) {
            NSLog(@"%@", dict);
        }];
        
        ADMessageModel * model = [[ADMessageModel alloc] init];
        model.from = [NSString stringWithFormat:@"%@", XMPPHANDLE.xmppStream.myJID];
        model.to = [[NSUserDefaults standardUserDefaults] stringForKey:CURRENT_CHAT];
        model.body = @"Hello";
        
        [XMPPHANDLE setAcceptOrDenyFriend:^BOOL(NSString * userID) {
            NSLog(@"%@", userID);
            return YES;
        }];
        
        [XMPPHANDLE sendMessage:model sendSuccess:^{
            
            NSLog(@"send success");
            
        } sendFailure:^(id error) {
            NSLog(@"%@", error);
        }];
        
        [XMPPHANDLE addFriend:@"Alice"];
        
        [XMPPHANDLE removeFriend:@"Alice"];
        
    } failure:^(id error) {
        NSLog(@"error");
    }];

    // testRegis
//    [XMPPHANDLE registerWithUserName:@"test" passWord:@"admin" success:^{
//        NSLog(@"register success");
//    } failure:^(id error) {
//        NSLog(@"%@", error);
//    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
