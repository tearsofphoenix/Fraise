/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "FRABasicPerformer.h"
#import "FRAApplicationDelegate.h"

@implementation FRABasicPerformer

VASingletonIMPDefault(FRABasicPerformer)

- (instancetype)init 
{
    if ((self = [super init]))
    {
		thousandFormatter = [[NSNumberFormatter alloc] init];
		[thousandFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[thousandFormatter setFormat:@"#,##0"];	
    }
    
    return self;
}


- (void)insertFetchRequests
{
	NSManagedObjectContext *managedObjectContext = FRAManagedObjectContext;
	NSEntityDescription *entityDescription;
	NSFetchRequest *request;
	NSSortDescriptor *sortDescriptor;
	fetchRequests = [[NSMutableDictionary alloc] init];
		
	entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Document"];
	
	entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"DocumentSortKeyName"];	
	
	entityDescription = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Project"];	
}


- (NSArray *)fetchAll:(NSString *)key
{
	return [FRAManagedObjectContext executeFetchRequest:[fetchRequests valueForKey:key] error:nil];
}


- (NSFetchRequest *)fetchRequest:(NSString *)key
{
	return [fetchRequests valueForKey:key];
}


- (id)createNewObjectForEntity:(NSString *)entity
{
	NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:FRAManagedObjectContext];
	
	return object;
}


- (void)removeAllObjectsForEntity:(NSString *)entity
{
	NSArray *array = [self fetchAll:entity];
	for (id item in array) {
		[FRAManagedObjectContext deleteObject:item];
	}
}


- (NSURL *)uriFromObject:(id)object
{
	if ([[object objectID] isTemporaryID] == YES) {
		[[FRAApplicationDelegate sharedInstance] saveAction:nil];
	}
	
	return [[object objectID] URIRepresentation];
}


- (id)objectFromURI:(NSURL *)uri
{
	NSManagedObjectContext *managedObjectContext = FRAManagedObjectContext;
	NSManagedObjectID *objectID = [[managedObjectContext persistentStoreCoordinator]
    managedObjectIDForURIRepresentation:uri];
	
	
	return [managedObjectContext objectWithID:objectID];	
}


- (void)removeAllItemsFromMenu:(NSMenu *)menu
{
	NSArray *array = [menu itemArray];
	for (id item in array) {
		[menu removeItem:item];
	}
}





- (void)insertSortOrderNumbersForArrayController:(NSArrayController *)arrayController
{
	NSArray *array = [arrayController arrangedObjects];
	NSInteger index = 0;
	for (id item in array) {
		[item setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
}


- (NSString *)genererateTemporaryPath
{
	NSInteger sequenceNumber = 0;
	NSString *temporaryPath;
	do {
		sequenceNumber++;
		temporaryPath = [NSString stringWithFormat:@"%d-%ld-%ld.%@", [[NSProcessInfo processInfo] processIdentifier], (NSInteger)[NSDate timeIntervalSinceReferenceDate], sequenceNumber, @"Fraise"];
		temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryPath];
	} while ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]);
	
	return temporaryPath;
}


- (NSString *)thousandFormatedStringFromNumber:(NSNumber *)number
{
	return [thousandFormatter stringFromNumber:number];
}


- (NSString *)resolveAliasInPath:(NSString *)path
{
	NSString *resolvedPath = nil;
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
//	NSMakeCollectable(url);
	
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedURL = CFURLCreateFromFSRef(NULL, &fsRef);
//				NSMakeCollectable(resolvedURL);
				if (resolvedURL != NULL) {
					resolvedPath = (NSString*)CFBridgingRelease(CFURLCopyFileSystemPath(resolvedURL, kCFURLPOSIXPathStyle));
//					NSMakeCollectable(resolvedPath);
				}
			}
		}
	}
	
	if (resolvedPath==nil) {
		return path;
	}
	
	return resolvedPath;
}

@end
