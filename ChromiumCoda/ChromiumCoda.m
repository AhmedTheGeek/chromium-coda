//
//  ChromiumCoda.m
//  ChromiumCoda
//  Created by Ahmed Hussein on 9/22/15.
//  Copyright (c) 2015 AhmedGeek

#import "ChromiumCoda.h"
#import "CodaPlugInsController.h"

@interface ChromiumCoda ()

- (id)initWithController:(CodaPlugInsController*)inController;

@end

//Global Constants
NSString *const GLOBALCRHOMELOCATION = @"/Applications/Google Chrome.app/";
NSString *const USERCRHOMELOCATION = @"~/Applications/Google Chrome.app/";
NSString *const CLIPATH = @"Contents/MacOS/Google Chrome";
NSString *projectPath = nil;

//Bundle/Plugin Path on Machine
NSString *bundlePath = nil;
NSString *launchLocation = nil;
NSString *projectLaunchPath = nil;

@implementation ChromiumCoda


//2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)aBundle
{
    return [self initWithController:aController];
}


//2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController*)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle
{
    bundlePath = plugInBundle.bundlePath;
    
    return [self initWithController:aController];
}


- (id)initWithController:(CodaPlugInsController*)inController
{
    if ( (self = [super init]) != nil )
    {
        controller = inController;
        
        
        //Run on Chrome Item
        [controller registerActionWithTitle:@"Run on Chrome" underSubmenuWithTitle:nil target:self selector:@selector(runOnChrome:) representedObject:nil keyEquivalent:@"^$R" pluginName:@"Chromium Coda"];
        //Create Manifest Item
        [controller registerActionWithTitle:NSLocalizedString(@"Create Manifest", @"Create Manifest") target:self selector:@selector(createManifest:)];
        //Package App/Extention item
        [controller registerActionWithTitle:NSLocalizedString(@"Package for Store", @"Package for Store") target:self selector:@selector(packageForStore:)];
        //Upload to store item
        [controller registerActionWithTitle:NSLocalizedString(@"Upload to Store", @"Upload to Store") target:self selector:@selector(publishApp:)];
        
        //Set launch path to global applications folder or user application folder
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        if([fileManager fileExistsAtPath:USERCRHOMELOCATION]){
            launchLocation = USERCRHOMELOCATION;
        }else if([fileManager fileExistsAtPath:GLOBALCRHOMELOCATION]){
            launchLocation = GLOBALCRHOMELOCATION;
        }else{
            launchLocation = nil;
        }
    }
    
    return self;
}


//Bundle Name
- (NSString*)name
{
    return @"Chromium Coda";
}

//Show notification with custom message
-(void) showNotification:(NSString *)message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Chromium Coda";
    notification.informativeText = message;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

}

-(BOOL) hasManifest{
    NSString *projectPath = [controller siteLocalPath];
    NSString *manifestPath = [NSString stringWithFormat:@"%@/%@", projectPath, @"manifest.json"];
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    
    return ([fileManager fileExistsAtPath:manifestPath]);
}

//Run on Chorme Action
- (void)runOnChrome:(id)sender
{
    //Project path and modified project path with trailing slash
    projectPath = controller.siteLocalPath;
    projectLaunchPath = [NSString stringWithFormat:@"%@/", projectPath];
    
    //Check if user has set local path for the project/site
    if ( projectPath != nil )
    {
        //Check if the project has manifest file
        if([self hasManifest]){
            //Check if launch location isn't null, and user have google chrome installed
            if(launchLocation != nil){
                
                NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
                NSURL *url = [NSURL fileURLWithPath:[workspace fullPathForApplication:launchLocation]];

                NSError *error = nil;
                NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"--load-and-launch-app=%@", projectLaunchPath],nil];
                
                 //Launch chrome with new instance and --load-and-launch-app flag
                [workspace launchApplicationAtURL:url options:NSWorkspaceLaunchNewInstance configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments] error:&error];
                //Handle error
                if(error == nil){
                    [self showNotification:[NSString stringWithFormat:@"%@ built successfully", [controller siteNickname]]];
                }else{
                    [self showNotification:[NSString stringWithFormat:@"%@ built failed, Error Code: %ld", [controller siteNickname], (long)error.code ]];
                }
            }else{
                [self showNotification:[NSString stringWithFormat:@"%@ failed to build, Google Chrome not installed!", [controller siteNickname]]];
            }
        }else{
            [self showNotification:[NSString stringWithFormat:@"%@ failed to build, manifest file not found", [controller siteNickname]]];
        }
        
    }else{
        [self showNotification:[NSString stringWithFormat:@"%@ failed to build, please set local path for this project", [controller siteNickname]]];
    }
    
}

//Create Manifest Action
- (void)createManifest:(id)sender{
    
    //Project path and modified project path with trailing slash
    projectPath = controller.siteLocalPath;
    projectLaunchPath = [NSString stringWithFormat:@"%@/", projectPath];
    
    NSString *manifestPath = [NSString stringWithFormat:@"%@/%@", projectPath, @"manifest.json"];
    
    //Check if project/site already has manifest file
    if([self hasManifest]){
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = @"Manifest.json already exists!";
        [alert runModal];
    }else{
        
        //Get manifest template file path and format its content
        NSString* sampleManifestPath = [NSString pathWithComponents:@[bundlePath, @"Contents", @"Resources", @"sampleManifest.json"]];
        
        NSString *manifestContent = [NSString stringWithContentsOfFile:sampleManifestPath usedEncoding:nil error:nil];
        
        manifestContent = [NSString stringWithFormat:manifestContent, controller.siteNickname, controller.siteNickname];
        
        //Write manifest file to the project
        [manifestContent writeToFile:manifestPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
        
        [self showNotification:[NSString stringWithFormat:@"%@ Manifest file successfully created!", [controller siteNickname]]];
    }
}


//Publish App Action
- (void) publishApp:(id)sender{
    //Open publish link in default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://chrome.google.com/webstore/developer/dashboard"]];
}

//Publish for Store Item
-(void) packageForStore:(id)sender{
    //Project path and modified project path with trailing slash
    projectPath = controller.siteLocalPath;
    projectLaunchPath = [NSString stringWithFormat:@"%@/", projectPath];
    
    if([self hasManifest]){
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        //chrome.exe --pack-extension=C:\myext
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        NSURL *url = [NSURL fileURLWithPath:[workspace fullPathForApplication:[NSString pathWithComponents:@[launchLocation, CLIPATH]]]];
        NSError *error = nil;
        NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"--pack-extension=%@", projectLaunchPath],nil];
        
        //Launch chrome --pack-extension
        [workspace launchApplicationAtURL:url options:NSWorkspaceLaunchNewInstance configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments] error:&error];
        
        //Check for Packed Project
        NSString *packagePath = [projectPath stringByDeletingLastPathComponent];
        NSString *projectFolderName = [projectPath lastPathComponent];
        NSString *crxPath = [NSString stringWithFormat:@"%@/%@", packagePath, [NSString stringWithFormat:@"%@.crx", projectFolderName]];
        NSString *pemPath = [NSString stringWithFormat:@"%@/%@", packagePath, [NSString stringWithFormat:@"%@.pem", projectFolderName]];
        
        NSURL *crxURL = [NSURL fileURLWithPath:crxPath];
        NSURL *pemURL = [NSURL fileURLWithPath:pemPath];
        
        while(![fileManager fileExistsAtPath:crxPath]){
            //Wait until finish packing
        }
        
        if([fileManager fileExistsAtPath:crxPath] && [fileManager fileExistsAtPath:pemPath]){
            NSArray *fileURLs = [NSArray arrayWithObjects:crxURL, pemURL,nil];
            [workspace activateFileViewerSelectingURLs:fileURLs];
        }
        
        [self showNotification:[NSString stringWithFormat:@"%@ was packaged for store successfully", [controller siteNickname]]];
        
    }else{
        [self showNotification:@"Failed to create package, manifest.json file not found"];
    }
}

@end