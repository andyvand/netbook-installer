//
//  SystemInformation.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import "SystemInformation.h"
#import <IOKit/IOKitLib.h>
#import <Foundation/NSPropertyList.h>

#define KERNEL_VERSION( __major__, __minor__, __bugfix__ )			(__major__ << 8 | __minor__ << 4 | __bugfix__)


#import <sys/sysctl.h>

#import <sys/mount.h>
#import <sys/ucred.h>
#import <sys/param.h>

#import <openssl/md5.h>
#import "checksum.h"


@implementation SystemInformation

- (id) init
{
	hostKernel = [self getKernelVersion:@"/"];
	generic = false;
	return self;
}
- (BOOL) dsdtInstalled
{
	return dsdtInstalled;
	
}
- (NSDictionary*) bootloaderDict
{
	return bootloaderDict;
}
- (NSString*) extensionsFolder
{
	return [[installPath stringByAppendingString: @"/Extra/"] stringByAppendingString:[machineInfo objectForKey:@"Extensions Directory"]];
}

- (NSString*) getMachineString
{
	NSString* retString = [machineInfo objectForKey:@"Long Name"];
	if(!retString) 
	{
		retString = [[NSString alloc] initWithString:@"General"];
	}
	return retString;
}

- (BOOL) remoteCDEnabled
{
	return remoteCDEnabled;
}

- (BOOL) hibernationDissabled
{
	return hibernationDissabled;
}
- (NSDictionary*) machineInfo
{
	// TODO: double check that machineInfo is not null
	return machineInfo;
}

- (NSString*) bootPartition
{
	return bootPartition;
}

- (NSString*) installPath
{
	//NSLog(@"Retuning install path");
	//NSLog(installPath);
	return installPath;
}

- (void) installPath: (NSString*) path
{
}

- (BOOL) quietBoot
{
	return quietBoot;
}

- (BOOL) bluetoothPatched
{
	return bluetoothPatched;
}

-(BOOL) efiHidden
{
	return efiHidden;
}
/*- (enum machine) machineType
{
	return machineType;
}*/

/*- (void) machineType: (enum machine) newMachineType
{
	machineType = newMachineType;
}*/

- (NSDictionary*) installedBootloader
{
	if(!installedBootloader) return @"None";
	return installedBootloader;
}

- (NSUInteger) bluetoothVendorId
{
	return bluetoothVendorId;
}
- (NSUInteger) bluetoothDeviceId
{
	return bluetoothDeviceId;
}


- (void) determineInstallState;
{

	//NSLog(@"Determine boot");
	bootloaderDict =  [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SupportFiles/bootloader.plist"]];	
	[self determinebootPartition];
	//NSLog(@"Determine machine type");

	[self determineMachineType];
	//NSLog(@"Determine dsdt type");

	[self determineDSDTState];
	
	//NSLog(@"Determine remotecd");

	[self determineRemoteCDState];
	
	//NSLog(@"Determine bluetooth");

	[self determineBluetoothState];

	//NSLog(@"Determine hibernate");

	[self determineHibernateState];
	
	//NSLog(@"Determine quiet boot");

	[self determineQuiteBootState];
	
	//NSLog(@"Determine hidden state");

	[self determineHiddenState];
	//NSLog(@"Determine gma");

	[self determineArchitecture];


	//	//NSLog(@"state");
	
}

// code example from http://snipplr.com/view/1645/given-a-mount-path-retrieve-a-usb-device-name/
- (void) determinebootPartition
{
	//NSFileManager* fileManager = [NSFileManager defaultManager];
	//NSError*	errs;
	NSDictionary* info = [self getFileSystemInformation: @"/"];

	bootPartition = [[NSString alloc] initWithString:[[info objectForKey:@"Mounted From"] substringFromIndex:[@"/dev/" length]]];
	installPath = [[NSString alloc] initWithString:@"/"];

	
	//NSLog(@"Root Device: %@\n", bootPartition);
	
	
	
//	//NSLog(@"Information about /: %@", [fileManager attributesOfFileSystemForPath: @"/" error:&errs]);
	
	
	
//	//NSLog(@"Info %@", [self getFileSystemInformation: @"/"]);

	
	[self determineTargetOS];
	[self determineBootloader];
	
	
}

//TODO: fix this as it currently crashes when a BAD path is sent
- (void) determinePartitionFromPath: (NSString*) path
{
	NSDictionary* info = [self getFileSystemInformation: path];

	bootPartition = [[NSString alloc] initWithString:[[info objectForKey:@"Mounted From"] substringFromIndex:[@"/dev/" length]]];
	installPath = [[NSString alloc] initWithString:path];

	//NSLog(@"Target Device: %@\n", bootPartition);
	
	
	[self determineTargetOS];

	[self determineBootloader];

	[self determineMachineType];
	[self determineDSDTState];
	[self determineRemoteCDState];
	[self determineBluetoothState];
	
	[self determineHibernateState];
	[self determineQuiteBootState];
	[self determineHiddenState];


}

- (void) determineMachineType
{
	//NSLog(@"machine type");
	NSDictionary*	machineplist= [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle]  resourcePath] stringByAppendingString:@"/SupportFiles/machine.plist"]];	
	NSEnumerator *enumerator = [machineplist objectEnumerator];
	NSDictionary* currentModel;

	
	
	int mib[2];
	char* model;
	size_t len;
	mib[0] = CTL_HW;
	mib[1] = HW_MODEL;
	len = sizeof(model);
	sysctl(mib, 2, NULL, &len, NULL, 0);
	model = malloc(len);
	sysctl(mib, 2, model, &len, NULL, 0);
	
	//NSLog(@"Model: %s", model);
	//NSLog(@"machinePlist: %@", machineplist);

	
	machineInfo = nil;
	//NSLog(@"Searching for %@", [NSString stringWithCString: model]);
	while ((currentModel = [enumerator nextObject])) {
		if([[currentModel objectForKey:@"Model Name"] length] <= strlen(model) && [[currentModel objectForKey:@"Model Name"] isEqualToString:[[NSString stringWithCString: model encoding: NSASCIIStringEncoding] substringToIndex:[[currentModel objectForKey:@"Model Name"] length]]])
		{
			machineInfo = [[NSDictionary alloc] initWithDictionary:currentModel copyItems:YES];
			break;
		}
	}
	
	if(!machineInfo || generic)
	{
		machineInfo = [[NSDictionary alloc] initWithDictionary:[machineplist objectForKey:@"General"] copyItems:YES];
	}
	
	if(!machineInfo) {
		NSLog(@"Unable to determine machine information. General machine does not exist");
		exit(-1);	// ALERT / FAIL
	} else {
		//NSLog(@"%@", machineInfo);
	}
	
	// validate machineInfo
	// TODO: make this a loop
	if(![machineInfo objectForKey:@"Support Files"])
	{
		NSLog(@"Error: Support Files not defined for machine");
	}
	
	if(![machineInfo objectForKey:@"Extensions Directory"])
	{
		NSLog(@"Error: Extensions Directory not defined for machine");
	}
	
	if(![machineInfo objectForKey:@"Long Name"])
	{
		NSLog(@"Error: Extensions Directory not defined for machine");
	}
	if(![machineInfo objectForKey:@"Bluetooth Vendor ID"])
	{
		NSLog(@"Error: Bluetooth Vendor ID not defined for machine");
	}
	if(![machineInfo objectForKey:@"Bluetooth Device ID"])
	{
		NSLog(@"Error: Bluetooth Device ID not defined for machine");
	}
	
	if(![[self machineInfo] objectForKey:@"Kext Blacklist"])
	{
		NSLog(@"Error: EFI Strings not defined for machine");
	}
	
	if(![machineInfo objectForKey:@"Kext Blacklist"])
	{
		NSLog(@"Error: EFI Strings not defined for machine");
	}	

	if(![machineInfo objectForKey:@"DSDT Patches"])
	{
		NSLog(@"Error: DSDT Patches not defined for machine");
	}	
	
	if(![machineInfo objectForKey:@"Install Paths"])
	{
		NSLog(@"Error: Install Paths not defined for machine");
	}
	
	
	NSLog(@"Current Model: %@", [machineInfo objectForKey:@"Long Name"]);
	free(model);
}

- (void) determineArchitecture
{
	int x86_64;
	size_t x86_64_size = sizeof(x86_64);
	if (!sysctlbyname("hw.optional.x86_64", &x86_64, &x86_64_size, NULL, 0)) {
		is64bit = x86_64;
	}
	else 	is64bit = 0;
}

- (BOOL) is64bit
{
	return is64bit;
}

- (void) determineDSDTState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];

	dsdtInstalled = [fileManager fileExistsAtPath: [installPath stringByAppendingString: @"/Extra/DSDT.aml"]];
//	//NSLog(@"DSDT");
}

- (void) determineRemoteCDState
{
	NSDictionary *dict;	
	dict = (NSDictionary*)CFPreferencesCopyMultiple(NULL,
													CFSTR("com.apple.NetworkBrowser"),
													kCFPreferencesCurrentUser,
													kCFPreferencesAnyHost);
	
	remoteCDEnabled = ([[dict objectForKey:@"EnableODiskBrowsing"] boolValue] &&
					   [[dict objectForKey:@"ODSSupported"] boolValue]);

}

- (void) determineHibernateState
{
	NSDictionary*	propertyList= [NSDictionary dictionaryWithContentsOfFile:[installPath stringByAppendingString: @"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]];
	
	if(!propertyList) {
		hibernationDissabled = false;
		return;
	}
	
	NSDictionary* powerStates = [propertyList objectForKey:@"Custom Profile"];
	NSDictionary* acPowerState = [powerStates objectForKey:@"AC Power"];
	NSDictionary* battPowerState = [powerStates objectForKey:@"Battery Power"];

	
	//NSLog(@"%@", [acPowerState valueForKey:@"Hibernate Mode"]);
	//NSLog(@"%@", [battPowerState valueForKey:@"Hibernate Mode"]);

	// If hibernation is enabled
	if(  [[acPowerState valueForKey:@"Hibernate Mode"] intValue] == 0 && 
	[[battPowerState valueForKey:@"Hibernate Mode"] intValue] == 0)
	{
		hibernationDissabled = true;
	}
	else
	{
		hibernationDissabled = false;
	}
	

}

- (void) determineQuiteBootState
{
	NSDictionary *	propertyList= [NSDictionary dictionaryWithContentsOfFile:[installPath stringByAppendingString: @"/Extra/com.apple.Boot.plist"]];
	NSString* quiet = [propertyList valueForKey:@"Quiet Boot"];
	
	quietBoot = [quiet isEqualToString:@"Yes"];
	

}

- (void) determineBluetoothState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];
	
	
	bluetoothPatched = !(([[[self machineInfo] objectForKey:@"Bluetooth Vendor ID"] isEqualToNumber:[NSNumber numberWithInt:0]]) || ([[[self machineInfo] objectForKey:@"Bluetooth Device ID"] isEqualToNumber:[NSNumber numberWithInt:0]]));
	
	bluetoothVendorId = [[machineInfo objectForKey:@"Bluetooth Vendor ID"] intValue];
	bluetoothDeviceId = [[machineInfo objectForKey:@"Bluetooth Device ID"] intValue];
	
}

- (void) determineHiddenState
{
	efiHidden = [self hiddenStateOfPath: [installPath stringByAppendingString:@"/Extra"]];
}

- (BOOL) hiddenStateOfPath: (NSString*) path;
{
	int retVal;
	if(![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		// Does not exist, so mark as hiddne hidden...
		return YES;
	}

	const char* cpath = [path cStringUsingEncoding:NSASCIIStringEncoding];
	struct stat fileStatus;
	retVal = stat(cpath, &fileStatus);
	
	return ((fileStatus.st_flags & UF_HIDDEN) ? YES : NO);
}


- (NSArray*) supportedBootloaders
{
	NSDictionary* bootloaders = [bootloaderDict objectForKey:@"Bootloaders"];
	NSDictionary* loader;
	NSEnumerator* enumerator = [bootloaders keyEnumerator];
	NSMutableArray* returnArray = [[NSMutableArray alloc] init];
	
	// Only return installable AND latest version
	while(loader = [enumerator nextObject])
	{
		// TODO: possibly copy array instead of including a refrence to the variable
		if([[[bootloaders objectForKey:loader] objectForKey:@"Installable"] isEqualToNumber:[NSNumber numberWithBool:YES]]) [returnArray addObject:[bootloaders objectForKey:loader]];

	}
	
	return returnArray;
}

- (void) determineBootloader
{
	return;
	
	NSDictionary* allbootloaders = [bootloaderDict objectForKey:@"Bootloaders"];

	NSDictionary* booter;
	NSEnumerator* bootloaders = [allbootloaders keyEnumerator];

	NSData* bootloader = [[NSData alloc] initWithContentsOfFile:[installPath stringByAppendingString:@"/boot"]];
	NSRange replaceByte;
	
	//NSMutableData* md5 =			[[NSMutableData alloc] initWithLength:16];

	
	unsigned char *digest;
	UInt8 i = 0;
	installedBootloader = nil;


	

	if(!bootloader || [bootloader length] == 0)
	{
		return;
	}	
	digest = 0; //MD5([bootloader bytes], [bootloader length], NULL);

	
	// Convert the string into an NSData type
	while(digest[i] != 0) {
		replaceByte.location = 16 - (i + 1);
		replaceByte.length = 1;
		//[md5 replaceBytesInRange:replaceByte withBytes:&(digest[i]) length:1];
		i++;
	}

	while((booter = [bootloaders nextObject]) && (installedBootloader == nil))
	{
		//if([md5 isEqualToData:[[[bootloaderDict objectForKey:@"Bootloaders"] objectForKey:booter] objectForKey:@"MD5"]]) installedBootloader = [[NSDictionary alloc] initWithDictionary:booter copyItems:YES];
	}
	
	
	[bootloader release];
	//[md5 release];
	
}

- (NSInteger) hostOS
{
	return hostKernel;
}

- (NSInteger) targetOS
{
	return installedKernel;
}
- (BOOL) determineTargetOS
{
	// Use the following for / detection only (recommended over the plist)
/*	gestaltSystemVersionMajor
	gestaltSystemVersionMinor
	gestaltSystemVersionBugFix*/
	
	installedKernel = [self getKernelVersion: installPath];
	return YES;
}

- (NSArray*) installableVolumes: (int) minVersions
{
	NSError* err;
	NSMutableArray* volumes = (NSMutableArray*) [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error: &err];
	
	// TODO: verify that the media is read / write
	
	int i = 0;
	while(i < [volumes count])
	{
		if([self getKernelVersion:[@"/Volumes/" stringByAppendingString:[[volumes objectAtIndex:i] stringByAppendingString:@"/mach_kernel"]]] < minVersions)
		{
			// Boot unsupported, remove volume from the list
			[volumes removeObjectAtIndex:i];
		}
		else
		{
			if([[[self getFileSystemInformation:[@"/Volumes/" stringByAppendingString:[volumes objectAtIndex:i]]] objectForKey:@"Mount Flags"] intValue] & MNT_RDONLY)
			{
				// remove if volume is read only
				[volumes removeObjectAtIndex:i];
			}
			else
			{
				i++;
			}
		}
	}
	
	return volumes;
	
	
		
	
	
	
}
	
- (NSInteger) getKernelVersion: (NSString*) kernelPath
{
	//NSLog(@"Get kernel version for %@", kernelPath);
	// Legacy support, remove this
	NSString* path = [kernelPath stringByReplacingOccurrencesOfString:@"/mach_kernel" withString:@"/"];

	int majorVersion = 0, minorVersion = 0, bugfixVersion = 0;
	NSScanner* scanner;
	NSDictionary* systemVersion = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingString:@"/System/Library/CoreServices/SystemVersion.plist"]];
	NSString* versionString = [systemVersion objectForKey:@"ProductVersion"];
	if(!versionString)
	{
		[systemVersion release];
		return 0;	// no kernel
	}
	
	versionString = [versionString stringByReplacingOccurrencesOfString:@"." withString:@" "];

	scanner = [NSScanner scannerWithString:versionString];
	
	[scanner scanInt:&majorVersion];
	[scanner scanInt:&minorVersion];
	[scanner scanInt:&bugfixVersion];

	[systemVersion release];
	return KERNEL_VERSION(majorVersion, minorVersion, bugfixVersion);
}

/**
 ** needsHelperPartition
 ** This method determins if the target device is bootable, if it isn't we need a helper partition with the boot files
 ** 
 **/
- (BOOL) needsHelperPartition
{
	// TODO: write this method...
	//Searching for "BSD Name" property = "diskXsY" INSIDE of IOSDCHCIBlockDevice, if it isn't loaded, it doesnt matter
	// This is only valid on the root device
	
	io_iterator_t			iter;
    io_service_t			service;
    kern_return_t			kr;
	CFDictionaryRef	dictRef;
	
	// ApplePS2MouseDevice is our parent in the I/O Registry
	dictRef = IOServiceMatching("IOSDHCIBlockDevice"); 
	if (!dictRef) {
		//NSLog(@"IOServiceMatching returned NULL.\n");
		return false;
	} 
	
	
	// Create an iterator over all matching IOService nubs.
	// This consumes a reference on dictRef.
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, dictRef, &iter);
	if (KERN_SUCCESS != kr) {
		//NSLog(@"IOServiceGetMatchingServices returned 0x%08x.\n", kr);
		return false;
	}
	
	
	//dictRef = CFPreferencesCopyMultiple(NULL ,CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	
	// Iterate across all instances of IOBlockStorageServices.
	while ((service = IOIteratorNext(iter))) {
		//NSLog([[NSString alloc] initWithCString:"Iterating...\n" encoding:NSASCIIStringEncoding]);
		
		io_registry_entry_t child;
		
		// Now that our parent has been found we can traverse the I/O Registry to find our driver.
		kr = IORegistryEntryGetChildEntry(service, kIOServicePlane, &child);
		if (KERN_SUCCESS != kr) {
			//NSLog(@"IORegistryEntryGetParentEntry returned 0x%08x.\n", kr);
		} else {
			// We're only interested in the parent object if it's our driver class.
			if (IOObjectConformsTo(child, "ApplePS2SynapticsTouchPad")) {
				// This is the function that results in ::setProperties() being called in our
				// kernel driver. The dictionary we created is passed to the driver here.
				
				
				//kr = IORegistryEntrySetCFProperties(child, dictRef);
				//NSLog([[NSString alloc] initWithCString:"Sent message to kext" encoding:NSASCIIStringEncoding]);
				//if (KERN_SUCCESS != kr) {
				//	//NSLog(@"IORegistryEntrySetCFProperties returned an error.\n", kr);
				//}
			} else {
				//NSLog(@"%s: Unable to locate Touchpad kext.\n", APP_ID);
				//				IOObjectRelease(parent);
				//				IOObjectRelease(service);
				
				//				return false
			}
			
			// Done with the parent object.
			IOObjectRelease(child);
		}
		
		// Done with the object returned by the iterator.
		IOObjectRelease(service);
	}
	
	if (iter != IO_OBJECT_NULL) {
		IOObjectRelease(iter);
		iter = IO_OBJECT_NULL;
	}
	
	if (dictRef) {
		CFRelease(dictRef);
		dictRef = NULL;
	} 
	
	return NO;
}

- (NSDictionary*) getFileSystemInformation: (NSString*) mountPoint
{
	NSMutableDictionary* returnDict = [[NSMutableDictionary alloc] init];
	struct statfs buffer;
	statfs([mountPoint cStringUsingEncoding:NSASCIIStringEncoding], &buffer);

//	[returnDict setObject:[[NSNumber alloc] initWithShort:buffer.f_otype] forKey:@"Filesystem Type"];	// reserved, always 0
//	[returnDict setObject:[[NSNumber alloc] initWithShort:buffer.f_oflags] forKey:@"Filesystem flags"];	// reserved, always 0
	
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_bsize] forKey:@"Block Size"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_iosize] forKey:@"Optimal IO block Size"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_blocks] forKey:@"Total Blocks"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_bfree] forKey:@"Free Blocks"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_bavail] forKey:@"Available Blocks"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_blocks] forKey:@"Total Blocks"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_blocks] forKey:@"Total Blocks"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_files] forKey:@"Files"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_ffree] forKey:@"Free Files"];
	[returnDict setObject:[[NSNumber alloc] initWithLong:buffer.f_flags] forKey:@"Mount Flags"];
	[returnDict setObject:[[NSString alloc] initWithCString:buffer.f_fstypename encoding:NSASCIIStringEncoding] forKey:@"File System"];
	[returnDict setObject:[[NSString alloc] initWithCString:buffer.f_mntonname encoding:NSASCIIStringEncoding] forKey:@"Mount Directory"];
	[returnDict setObject:[[NSString alloc] initWithCString:buffer.f_mntfromname encoding:NSASCIIStringEncoding] forKey:@"Mounted From"];
	
	return returnDict;
}

- (void) genericMachineType
{
	generic = YES;
}

- (void) printStatus		// Status of target / system
{
	NSLog(@"Mountpoint Statistics: %@\n", [self getFileSystemInformation: [self installPath]]);
	NSLog(@"HostOS: %d\n", [self hostOS]);
	NSLog(@"TargetOS: %d\n", [self targetOS]);
	NSLog(@"InstallPath: %@\n", [self installPath]);
	NSLog(@"Boot Partition: %@\n", [self bootPartition]);

	NSLog(@"InstalledBootloader: %@\n", [self installedBootloader]);
	NSLog(@"BluetoothVendorID: %d\n", [self bluetoothVendorId]); 
	NSLog(@"BluetoothDeviceID: %d\n", [self bluetoothDeviceId]);
	NSLog(@"BluetoothPatched: %s\n", (bluetoothPatched ? "Yes" : "No"));
	NSLog(@"DSDT Installed: %s\n", ([self dsdtInstalled]? "Yes" : "No"));
	NSLog(@"RemoteCD Enabled: %s", ([self remoteCDEnabled]? "Yes" : "No"));
	NSLog(@"Hibernation Disabled: %s", ([self hibernationDissabled]? "Yes" : "No"));
	NSLog(@"QuietBoot Enabled: %s", ([self quietBoot]? "Yes" : "No"));
	NSLog(@"/Extra Hidden: %s", ([self efiHidden]? "Yes" : "No"));
	NSLog(@"Force Generic: %s", (generic? "Yes" : "No"));
	
	//NSDictionary* machineInfo;
}

@end