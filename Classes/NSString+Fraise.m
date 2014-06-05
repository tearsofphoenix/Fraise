/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "NSString+Fraise.h"

#import "FRAStandardHeader.h"

@implementation NSString (NSStringFraise)


+ (NSString *)dateStringForDate:(NSCalendarDate *)date formatIndex:(NSInteger)index
{	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];	
	
	if (index == 1) {
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm Z"];
	} else if (index == 2) {
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	} else if (index == 3) {
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	} else if (index == 4) {
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	} else if (index == 5) {
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	} else if (index == 6) {
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
	} else if (index == 7) {
		[dateFormatter setDateStyle:NSDateFormatterFullStyle];
		[dateFormatter setTimeStyle:NSDateFormatterFullStyle];
	} else if (index == 8) {
		[dateFormatter setDateFormat:[FRADefaults valueForKey:@"UserDateFormat"]];
	} else {
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
	}
	
	return [dateFormatter stringFromDate:date];
}


@end
