//
//  CordovaPGP.m
//  PGP Demo
//
//  Created by James Knight on 6/11/15.
//  Copyright (c) 2015 Gradient. All rights reserved.
//

#import "CordovaPGP.h"
#import "PGP.h"

typedef void (^CordovaPGPErrorBlock)(NSError *);


#pragma mark - CordovaPGP extension


@interface CordovaPGP ()

- (void(^)(NSError *))createErrorBlockForCommand:(CDVInvokedUrlCommand *)command;

@end


#pragma mark - CordovaPGP implementation


@implementation CordovaPGP


#pragma mark Methods


- (void)signAndEncryptMessage:(CDVInvokedUrlCommand *)command {
    
    // Define error callback:
    CordovaPGPErrorBlock errorBlock = [self createErrorBlockForCommand:command];
    
    // Perform command:
    [self.commandDelegate runInBackground:^{
        
        // Get the arguments from the command:
        NSArray *publicKeys = [command.arguments objectAtIndex:0];
        NSString *privateKey = [command.arguments objectAtIndex:1];
        NSString *text = [command.arguments objectAtIndex:2];
        
        // Sign the text first:
        PGP *signer = [PGP signerWithPrivateKey:privateKey];
        [signer signData:[text dataUsingEncoding:NSUTF8StringEncoding] completionBlock:^(NSData *signedData) {
            
            // Signing was successful, now encrypt the text:
            PGP *encryptor = [PGP encryptor];
            
            [encryptor encryptData:signedData publicKeys:publicKeys completionBlock:^(NSData *encryptedData) {
                
                NSString *result = [[NSString alloc] initWithData:encryptedData encoding:NSUTF8StringEncoding];
                
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                  messageAsString:result];
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
            } errorBlock:errorBlock];
            
        } errorBlock:errorBlock];
    }];
}


- (void)decryptAndVerifyMessage:(CDVInvokedUrlCommand *)command {
    
    // Define error callback:
    CordovaPGPErrorBlock errorBlock = [self createErrorBlockForCommand:command];
    
    // Perform command:
    [self.commandDelegate runInBackground:^{
        
        // Get the arguments from the command:
        NSString *privateKey = [command.arguments objectAtIndex:0];
        NSArray *publicKeys = [command.arguments objectAtIndex:1];
        NSString *msg = [command.arguments objectAtIndex:2];
        
        PGP *decryptor = [PGP decryptorWithPrivateKey:privateKey];
        [decryptor decryptData:[msg dataUsingEncoding:NSUTF8StringEncoding] completionBlock:^(NSData *decryptedData) {
            
            PGP *verifier = [PGP verifier];
            [verifier verifyData:decryptedData publicKeys:publicKeys completionBlock:^(NSData *verifiedData, NSArray *verifiedKeys) {
                
                // TODO: Change verifyData so that it returns the message as well!
                
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                  messageAsArray:verifiedKeys];
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
            } errorBlock:errorBlock];
            
        } errorBlock:errorBlock];
    }];
}


- (void)generateKeyPair:(CDVInvokedUrlCommand *)command {
    
    // Define error callback:
    CordovaPGPErrorBlock errorBlock = [self createErrorBlockForCommand:command];
    
    // Perform command:
    [self.commandDelegate runInBackground:^{
        NSDictionary *options = [command.arguments objectAtIndex:0];
        
        PGP *generator = [PGP keyGenerator];
        [generator generateKeysWithOptions:options completionBlock:^(NSString *publicKey, NSString *privateKey) {
            
            NSArray *keys = @[privateKey, publicKey];
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                               messageAsArray:keys];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
        } errorBlock:errorBlock];
    }];
}


#pragma mark Private methods


- (void(^)(NSError *))createErrorBlockForCommand:(CDVInvokedUrlCommand *)command {
    return ^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:error.description];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    };
}

@end
