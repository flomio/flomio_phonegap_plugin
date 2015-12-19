/*
FLOPlugin.h
*/

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import "ReaderInterface.h"
#import "winscard.h"
#import "ft301u.h"

@protocol FeitianReaderDelegate <NSObject>
@optional

- (void)didFeitianReaderSendUUID:(NSString*)uuid fromDevide:(NSString *)sn;

@end

@interface FLOPlugin : CDVPlugin <ReaderInterfaceDelegate> {
    
    BOOL cardIsAttached;
    
    SCARDCONTEXT gContxtHandle;
    SCARDHANDLE  gCardHandle;
    
    BOOL isCardConnected;
    
    NSString *serialNumber;
    NSString *asyncCallbackId;
}

@property id<FeitianReaderDelegate> delegate;
@property (nonatomic,strong) ReaderInterface *readInf;


@end
