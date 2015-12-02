/*
FLOPlugin.m
*/

#import "FLOPlugin.h"

@implementation FLOPlugin

/** Starts the reader polling for tags */
- (void)startPolling:(CDVInvokedUrlCommand*)command
{
    isCardConnected = NO;
    _readInf = [[ReaderInterface alloc]init];
    [_readInf setDelegate:self];
    SCardEstablishContext(SCARD_SCOPE_SYSTEM,NULL,NULL,&gContxtHandle);
    
    asyncCallbackId = command.callbackId;
//    [self active];
}

/** Stops the reader polling for tags */
- (void)stopPolling:(CDVInvokedUrlCommand*)command {
    
//  [self inactive];
}

-(void)readCard
{
    LONG iRet = 0;
    DWORD dwActiveProtocol = -1;
    char mszReaders[128] = "";
    DWORD dwReaders = -1;
    
    iRet = SCardListReaders(gContxtHandle, NULL, mszReaders, &dwReaders);
    if(iRet != SCARD_S_SUCCESS)
    {
        NSLog(@"SCardListReaders error %08x",iRet);
        return;
    }
    
    isCardConnected = YES;
    
    iRet = SCardConnect(gContxtHandle,mszReaders,SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,&gCardHandle,&dwActiveProtocol);
    if (iRet != 0) {
        
        //NSLog(@"SUCCESS!!!");
        NSLog(@"Read Failed.");
        
    }
    else {
        
        unsigned char patr[33];
        DWORD len = sizeof(patr);
        iRet = SCardGetAttrib(gCardHandle,NULL, patr, &len);
        if(iRet != SCARD_S_SUCCESS)
        {
            NSLog(@"SCardGetAttrib error %08x",iRet);
        }
        
        NSMutableData *tmpData = [NSMutableData data];
        [tmpData appendBytes:patr length:len];
        
        NSString* dataString= [NSString stringWithFormat:@"%@",tmpData];
        NSRange begin = [dataString rangeOfString:@"<"];
        NSRange end = [dataString rangeOfString:@">"];
        NSRange range = NSMakeRange(begin.location + begin.length, end.location- begin.location - 1);
        dataString = [dataString substringWithRange:range];
        
        DWORD pcchReaderLen;
        DWORD pdwState;
        DWORD pdwProtocol;
        len = sizeof(patr);
        pcchReaderLen = sizeof(mszReaders);
        
        iRet =  SCardStatus(gCardHandle,mszReaders,&pcchReaderLen,&pdwState,&pdwProtocol,patr,&len);
        if(iRet != SCARD_S_SUCCESS)
        {
            NSLog(@"SCardStatus error %08x",iRet);
            
        } else {
            
            [self sendCommand:@"FFCA000000"];
        }
        
    }
    
}

-(void)changeCardState
{
    
    NSLog(@"READ!!!");
    //[self sendCommand:@"FFCA000000"];
    
}

-(void)disAccDig {
    
    //[NSTimer scheduledTimerWithTimeInterval:7.0 target:self selector:@selector(foo) userInfo:nil repeats:YES];
    
    [self readCard];
}

-(void)sendCommand:(NSString *)command
{
    
    LONG iRet = 0;
    unsigned  int capdulen;
    unsigned char capdu[512];
    unsigned char resp[512];
    unsigned int resplen = sizeof(resp) ;
    
    NSString* tempBuf = [NSString string];
    
    
    if(([command length] == 0 ) )
    {
        
        
        return;
    }
    else
    {
        if([command length] < 5 )
        {
            NSLog(@"Invalid APDU.");
            return;
        }
    }
    
    
    tempBuf = command;
    
    NSString* comand = [tempBuf stringByAppendingString:@"\n"];
    const char *buf = [tempBuf UTF8String];
    NSMutableData *data = [NSMutableData data];
    uint32_t len = strlen(buf);
    
    //to hex
    char singleNumberString[3] = {'\0', '\0', '\0'};
    uint32_t singleNumber = 0;
    for(uint32_t i = 0 ; i < len; i+=2)
    {
        if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
        {
            singleNumberString[0] = buf[i];
            singleNumberString[1] = buf[i + 1];
            sscanf(singleNumberString, "%x", &singleNumber);
            uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
            [data appendBytes:(void *)(&tmp) length:1];
        }
        else
        {
            break;
        }
    }
    for (int kkk=0; kkk<1; kkk++) {
        [data getBytes:capdu];
        resplen = sizeof(resp);
        capdulen = [data length];
        SCARD_IO_REQUEST pioSendPci;
        
        iRet=SCardTransmit(gCardHandle,&pioSendPci, (unsigned char*)capdu, capdulen,NULL,resp, &resplen);
        if (iRet != 0) {
            
            NSLog(@"ERROR SCardTransmit ret %08X.", iRet);
            NSMutableData *tmpData = [NSMutableData data];
            [tmpData appendBytes:resp length:capdulen*2];
            
            /*
             if(powerOn.enabled == NO){
             
             NSString* sending = NSLocalizedString(@"SEND_DATA", nil);
             NSString* sendComand = [NSString stringWithFormat:
             @"%@：%@",sending,comand];
             NSString* disText = disTextView.text;
             disText = [disText stringByAppendingString:sendComand];
             
             NSString* returnData = NSLocalizedString(@"RETURN_DATA", nil);
             NSString* errMSG = [NSString stringWithFormat:
             @"%@：%08X",@"ERROR SCardTransmit ret ",iRet];
             
             returnData = [returnData stringByAppendingString:errMSG];
             returnData = [returnData stringByAppendingString:@"\n"];
             disText = [disText stringByAppendingString:returnData];
             disTextView.text = disText;
             [self moveToDown];
             
             disText = disTextView.text;
             disTextView.text = disText;
             }
             
             sendCommand.enabled = YES;
             
             */
        }
        else {
            
            NSMutableData *tmpData = [NSMutableData data];
            [tmpData appendBytes:capdu length:capdulen*2];
            
            NSString* sending = NSLocalizedString(@"SEND_DATA", nil);
            NSString* sendComand = [NSString stringWithFormat:
                                    @"%@：%@",sending,comand];
            
            
            NSLog(@"sendCommand:%@",sendComand);
            
            /*
             NSString* disText = disTextView.text;
             disText = [disText stringByAppendingString:sendComand];
             disTextView.text = disText;
             */
            
            NSMutableData *RevData = [NSMutableData data];
            [RevData appendBytes:resp length:resplen];
            
            NSString* recData = [NSString stringWithFormat:@"%@", RevData];
            NSRange begin = [recData rangeOfString:@"<"];
            NSRange end = [recData rangeOfString:@">"];
            NSRange start = NSMakeRange(begin.location + begin.length, end.location - begin.location-1);
            recData = [recData substringWithRange:start];
            recData = [recData stringByAppendingString:@"\n"];
            
            NSString* returnData = NSLocalizedString(@"RETURN_DATA", nil);
            
            //recData = [NSString stringWithFormat:@"%@：%@",returnData,recData];
            
            NSString *trimmed = [recData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            trimmed = [trimmed stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSString *ack = [trimmed substringFromIndex: [trimmed length] - 4];
            
            NSLog(@"recData:%@, %@",trimmed, ack);
            
            if ([ack intValue] == 9000) {
                [_delegate didFeitianReaderSendUUID:[trimmed substringToIndex:[trimmed length] - 4] fromDevide:serialNumber];
            }
            
            
            /*
             disText = disTextView.text;
             disText = [disText stringByAppendingString:recData];
             disTextView.text = disText;
             [self moveToDown];
             
             sendCommand.enabled = YES;
             
             */
        }
    }
    
}

-(IBAction)getSerialNumber
{
    char buffer[20] = {0};
    unsigned int length = sizeof(buffer);
    LONG iRet = FtGetSerialNum(0,&length, buffer);
    if(iRet != 0 ){
        serialNumber = @"Get serial number ERROR.";
    }else {
        NSData *temp = [NSData dataWithBytes:buffer length:length];
        serialNumber = [NSString stringWithFormat:@"%@\n", temp];
    }
}

#pragma mark ReaderInterfaceDelegate Methods

- (void) cardInterfaceDidDetach:(BOOL)attached
{
    NSLog(@"BOOL:%i",attached);
    cardIsAttached = attached;
    
    if (attached == 1 && !isCardConnected) {
        //
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self performSelector:@selector(sendCommand:) withObject:@"FFCA000000" afterDelay:10.0];
            [self sendCommand:@"FFCA000000"];
        });
        
        
        //[self sendCommand:@"FFCA000000"];
    } else if (attached == 0 && isCardConnected) {
        isCardConnected = NO;
    }
    
    //[self performSelectorOnMainThread:@selector(changeCardState) withObject:nil waitUntilDone:YES];
    
}

- (void) readerInterfaceDidChange:(BOOL)attached
{
    NSLog(@"RIDC %@ %d",NSStringFromSelector(_cmd),attached);
    
    if (attached) {
        [self getSerialNumber];
        [self performSelectorOnMainThread:@selector(disAccDig) withObject:nil waitUntilDone:YES];
    }
    else{
        [self performSelectorOnMainThread:@selector(disPowerOff) withObject:nil waitUntilDone:YES];
    }
    
}

@end