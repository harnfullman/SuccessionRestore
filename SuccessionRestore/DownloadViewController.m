//
//  DownloadViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "DownloadViewController.h"
#include <sys/sysctl.h>
#import "ZipArchive/ZipArchive.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.activityLabel.text = @"Finding IPSW API...";
    NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", deviceModel, deviceBuild];
    self.activityLabel.text = ipswAPIURLString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startDownloadingButton:(id)sender {
    self.activityLabel.text = @"Preparing download...";
    //Removes all files in /var/mobile/Media/Succession to delete any mess from previous uses
    NSFileManager* fm = [[NSFileManager alloc] init];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:@"/var/mobile/Media/Succession"];
        NSError* error = nil;
        BOOL res;
        NSString* file;
        while (file =
               
               [en nextObject]) {
            res = [fm removeItemAtPath:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:file] error:&error];
            if (!res && error) {
                self.activityLabel.text = [NSString stringWithFormat:@"Error deleting files: %@", [error localizedDescription]];
            }
        }
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/" withIntermediateDirectories:NO attributes:nil error:nil];
    self.activityLabel.text = @"Finding IPSW...";
    NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", deviceModel, deviceBuild];
    NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
    NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              NSString * activityLabelText = [downloadLinkString stringByAppendingString:@"Found IPSW at"];
                                              self.activityLabel.text = activityLabelText;
                                              _downloadLink = [NSURL URLWithString:downloadLinkString];
                                              NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:_downloadLink];
                                              [task resume];
                                          }];
    [getDownloadLinkTask resume];
    
    /*
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Succession/extracted" withIntermediateDirectories:NO attributes:nil error:nil];
     //unzips the ipsw
     NSTask *unzipIPSW = [[NSTask alloc] init];
     [unzipIPSW setLaunchPath:@"/bin/unzip"];
     NSArray *unzipIPSWArgs = [NSArray arrayWithObjects:@"-a", @"/var/mobile/Media/Succession/ipsw.zip", @"-d", @"/var/mobile/Media/Succession/ipsw", nil];
     [unzipIPSW setArguments:unzipIPSWArgs];
     [unzipIPSW launch];
     if ([deviceModel isEqualToString:@"iPhone4,1"]) {
     
     } else {
     UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *closeApp) {
     exit(0);
     }];
     [deviceNotSupported addAction:okAction];
     [self presentViewController:deviceNotSupported animated:YES completion:nil];
     }
     //creates a bool to determine if the dmg needs to be decrypted before mounting
     BOOL needsDecryption = YES;
     //checks to see if the DMG is from an iOS 10 or later version. If so, the dmg is not encrypted
     //if (CFCoreFoundationVersionNumber > 1300) {
     //  needsDecryption = NO;}
     if (needsDecryption == YES) {
     if ([deviceModel isEqualToString:@"iPhone4,1"]) {
     if ([deviceBuild isEqualToString:@"12H321"]) {
     [[NSFileManager defaultManager] moveItemAtPath:@"/var/mobile/Media/Succession/ipsw/058-24033-023.dmg" toPath:@"/var/mobile/Media/Succession/rfs-encrypted.dmg" error:nil];
     NSTask *decryptDMG = [[NSTask alloc] init];
     [decryptDMG setLaunchPath:@"/Applications/SuccessionRestore.app/dmg"];
     NSArray *decryptDMGArgs = [NSArray arrayWithObjects:@"extract", @"/var/mobile/Media/Succession/rfs-encrypted.dmg", @"/var/mobile/Media/Successsion/rfs.dmg", @"-k", @"8fd9823be521060b9160272962fc2f65520de7b5ab55fe574953997e3ee5306d7bab5e02", nil];
     [decryptDMG setArguments:decryptDMGArgs];
     [decryptDMG launch];
     } else {
     UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9.3.5 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *closeApp) {
     exit(0);
     }];
     [deviceNotSupported addAction:okAction];
     [self presentViewController:deviceNotSupported animated:YES completion:nil];}
     }
     } else {
     } */
}
- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError * error;
    [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
    if (error != nil) {
        self.activityLabel.text = [NSString stringWithFormat:@"Error moving downloaded ipsw: %@", error];
    } else {
        self.activityLabel.text = @"Unzipping...";
        ZipArchive * unzipIPSW = [[ZipArchive alloc] init];
        if( [unzipIPSW UnzipOpenFile:@"/var/mobile/Media/Succession/ipsw.zip"] ) {
            if( [unzipIPSW UnzipFileTo:[@"/var/mobile/Media/Succession" stringByAppendingPathComponent:@"extracted"] overWrite:YES] != NO ) {
                self.activityLabel.text = @"Cleaning up...";
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Succession/ipsw.zip" error:&error];
                if (error != nil) {
                    self.activityLabel.text = [NSString stringWithFormat:@"Error deleting IPSW: %@", [error localizedDescription]];
                } else {
                    self.activityLabel.text = @"Get largest file here";
                }
            }
            
            [unzipIPSW UnzipCloseFile];
        }
    }
}
- (void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float totalSize = (totalBytesExpectedToWrite/1024)/1024.f;
    float writtenSize = (totalBytesWritten/1024)/1024.f;
    self.activityLabel.text = [NSString stringWithFormat:@"%.2f of %.2f MB", writtenSize, totalSize];
}
@end
