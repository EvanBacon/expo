

#import <FirebaseCore/FirebaseCore.h>
#import <EXCore/EXUtilities.h>
#import <EXFirebaseApp/EXFirebaseApp.h>
#import <EXFirebaseApp/EXFirebaseAppUtil.h>

@implementation EXFirebaseApp

EX_EXPORT_MODULE(ExpoFirebaseApp);

/**
 * Initialize a new firebase app instance or ignore if currently exists.
 * @return
 */
EX_EXPORT_METHOD_AS(initializeApp,
                    initializeApp:(NSString *)appDisplayName
                    options:(NSDictionary *)options
                    resolver:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  [EXUtilities performSynchronouslyOnMainThread:^{
    FIRApp *existingApp = [EXFirebaseAppUtil getApp:appDisplayName];
    if (existingApp && (![options[@"apiKey"] isEqualToString:existingApp.options.APIKey] || ![options[@"appId"] isEqualToString:existingApp.options.googleAppID])) {
      [existingApp deleteApp:^(BOOL success) {
        [self _initializeApp:appDisplayName options:options resolver:resolve rejecter:reject];
      }];
      
    } else {
      [self _initializeApp:appDisplayName options:options resolver:resolve rejecter:reject];
    }
  }];
}

- (void)_initializeApp:(NSString *)appDisplayName
               options:(NSDictionary *)options
              resolver:(EXPromiseResolveBlock)resolve
              rejecter:(EXPromiseRejectBlock)reject
{
  [EXUtilities performSynchronouslyOnMainThread:^{
    FIRApp *existingApp = [EXFirebaseAppUtil getApp:appDisplayName];
    
    if (!existingApp) {
      FIROptions *firOptions = [[FIROptions alloc] initWithGoogleAppID:options[@"appId"] GCMSenderID:options[@"messagingSenderId"]];
      
      firOptions.APIKey = options[@"apiKey"];
      firOptions.projectID = options[@"projectId"];
      firOptions.clientID = options[@"clientId"];
      firOptions.trackingID = options[@"trackingId"];
      firOptions.databaseURL = options[@"databaseURL"];
      firOptions.storageBucket = options[@"storageBucket"];
      firOptions.androidClientID = options[@"androidClientId"];
      firOptions.deepLinkURLScheme = options[@"deepLinkURLScheme"];
      firOptions.bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
      
      NSString *appName = [EXFirebaseAppUtil getAppName:appDisplayName];
      if (appName == nil || [appName isEqualToString:DEFAULT_APP_NAME]) {
        [FIRApp configureWithOptions:firOptions];
      } else {
        [FIRApp configureWithName:appName options:firOptions];
      }
    }
    
    resolve(@{@"result": @"success"});
    
  }];
}

/**
 * Delete a firebase app
 * @return
 */
EX_EXPORT_METHOD_AS(deleteApp,
                    deleteApp:(NSString *)appDisplayName
                    resolver:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  FIRApp *existingApp = [EXFirebaseAppUtil getApp:appDisplayName];
  
  if (!existingApp) {
    return resolve(nil);
  }
  
  [existingApp deleteApp:^(BOOL success) {
    if (success) {
      resolve(nil);
    } else {
      reject(@"app/delete-app-failed", @"Failed to delete the specified app.", nil);
    }
  }];
}

/**
 * React native constant exports - exports native firebase apps mainly
 * @return NSDictionary
 */
- (NSDictionary *)constantsToExport
{
  NSMutableDictionary *constants = [NSMutableDictionary new];
  NSDictionary *firApps = [FIRApp allApps];
  NSMutableArray *appsArray = [NSMutableArray new];
  
  for (id key in firApps) {
    NSMutableDictionary *appOptions = [NSMutableDictionary new];
    FIRApp *firApp = firApps[key];
    FIROptions *firOptions = [firApp options];
    appOptions[@"name"] = [EXFirebaseAppUtil getAppDisplayName:firApp.name];
    appOptions[@"apiKey"] = firOptions.APIKey;
    appOptions[@"appId"] = firOptions.googleAppID;
    appOptions[@"databaseURL"] = firOptions.databaseURL;
    appOptions[@"messagingSenderId"] = firOptions.GCMSenderID;
    appOptions[@"projectId"] = firOptions.projectID;
    appOptions[@"storageBucket"] = firOptions.storageBucket;
    
    // missing from android sdk / ios only:
    appOptions[@"clientId"] = firOptions.clientID;
    appOptions[@"trackingId"] = firOptions.trackingID;
    appOptions[@"androidClientID"] = firOptions.androidClientID;
    appOptions[@"deepLinkUrlScheme"] = firOptions.deepLinkURLScheme;
    
    [appsArray addObject:appOptions];
  }
  
  constants[@"apps"] = appsArray;
  return constants;
}

@end
