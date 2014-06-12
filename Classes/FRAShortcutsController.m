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

#import "FRAShortcutsController.h"
#import "FRACommandsController.h"
#import "FRASnippetsController.H"
#import "VASnippet.h"
#import "VACommand.h"

@implementation FRAShortcutsController

VASingletonIMPDefault(FRAShortcutsController)

- (void)registerSnippetShortcutWithEvent:(NSEvent *)event
{
	VASnippet *snippet = [[FRASnippetsController sharedInstance] selectedSnippet];
	[snippet setShortcutModifier: [event modifierFlags]];
	[snippet setShortcutMenuItemKeyString: [self menuItemKeyStringFromEvent:event]];
	[snippet setShortcutDisplayString: [[self plainModifierStringFromEvent:event] stringByAppendingString: [self plainKeyStringFromEvent:event]]];
}


- (void)unregisterSelectedSnippetShortcut
{
	VASnippet *snippet = [[FRASnippetsController sharedInstance] selectedSnippet];
	
	[snippet setShortcutModifier: 0];
	[snippet setShortcutMenuItemKeyString: nil];
	[snippet setShortcutDisplayString: nil];
}


- (void)registerCommandShortcutWithEvent:(NSEvent *)event
{
	VACommand *command = [[FRACommandsController sharedInstance] selectedCommand];
	[command setShortcutModifier: [event modifierFlags]];
	[command setShortcutMenuItemKeyString: [self menuItemKeyStringFromEvent:event]];
	[command setShortcutDisplayString: [[self plainModifierStringFromEvent:event] stringByAppendingString:[self plainKeyStringFromEvent:event]]];
}


- (void)unregisterSelectedCommandShortcut
{
	VACommand *command = [[FRACommandsController sharedInstance] selectedCommand];
	
	[command setShortcutModifier: 0];
	[command setShortcutMenuItemKeyString: nil];
	[command setShortcutDisplayString: nil];
}


- (NSString *)menuItemKeyStringFromEvent:(NSEvent *)event
{
	NSString *returnString;
	unichar character[1];
	NSInteger keyCode = [event keyCode];
	
	if (keyCode == 0x7A) {
		character[0] = NSF1FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x78) {
		character[0] = NSF2FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x63) {
		character[0] = NSF3FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x76) {
		character[0] = NSF4FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x60) {
		character[0] = NSF5FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x61) {
		character[0] = NSF6FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x62) {
		character[0] = NSF7FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x64) {
		character[0] = NSF8FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x65) {
		character[0] = NSF9FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6D) {
		character[0] = NSF10FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x67) {
		character[0] = NSF11FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6F) {
		character[0] = NSF12FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x69) {
		character[0] = NSF13FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6B) {
		character[0] = NSF14FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x71) {
		character[0] = NSF15FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6A) {
		character[0] = NSF16FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x40) {
		character[0] = NSF17FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x4F) {
		character[0] = NSF18FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x50) {
		character[0] = NSF19FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	}
	
	else if (keyCode == 0x34) returnString = [NSString stringWithFormat:@"%C", 0x2324]; // enter
	else if (keyCode == 0x24) returnString = [NSString stringWithFormat:@"%C", 0x21B5]; // return
	else if (keyCode == 0x35) returnString = [NSString stringWithFormat:@"%C", 0x238B]; // escape
	else if (keyCode == 0x30) returnString = [NSString stringWithFormat:@"%C", 0x21E5]; // tab
	else if (keyCode == 0x33) returnString = [NSString stringWithFormat:@"%C", 0x232B]; // backwards delete
	else if (keyCode == 0x31) returnString = [NSString stringWithFormat:@"%C", 0x2423]; // space
	else if (keyCode == 0x47) returnString = [NSString stringWithFormat:@"%C", 0x2327]; // clear key
	else if (keyCode == 0x4D) returnString = [NSString stringWithFormat:@"%C", 0x2191]; // up arrow
	else if (keyCode == 0x7D) returnString = [NSString stringWithFormat:@"%C", 0x2193]; // down arrow
	else if (keyCode == 0x7B) returnString = [NSString stringWithFormat:@"%C", 0x2190]; // left arrow
	else if (keyCode == 0x7C) returnString = [NSString stringWithFormat:@"%C", 0x2192]; // right arrow
	else if (keyCode == 0x75) returnString = [NSString stringWithFormat:@"%C", 0x2326]; // forward delete
	else if (keyCode == 0x73) returnString = [NSString stringWithFormat:@"%C", 0x2196]; // home
	else if (keyCode == 0x77) returnString = [NSString stringWithFormat:@"%C", 0x2198]; // end
	else if (keyCode == 0x74) returnString = [NSString stringWithFormat:@"%C", 0x21DE]; // page up
	else if (keyCode == 0x79) returnString = [NSString stringWithFormat:@"%C", 0x21DF]; // page down
	else if (keyCode == 0x72) returnString = @"?"; // help
	
	else {
		if ([event modifierFlags] & NSShiftKeyMask) { // If Shift is pressed, get the character this way so the "correct" character will be displayed, e.g. 3 and not #
			OSStatus err;
			
			static UInt32 deadKeyState = 0;
			UniCharCount maxStringLength = 4;
			UniCharCount actualStringLength;
			UniChar unicodeString[4];
			
			TISInputSourceRef kbInputSourceRef = (TISInputSourceRef) TISCopyCurrentKeyboardLayoutInputSource();
			
			CFDataRef uchrDataRef = (CFDataRef)TISGetInputSourceProperty(kbInputSourceRef, kTISPropertyUnicodeKeyLayoutData);
				
			err = UCKeyTranslate((const UCKeyboardLayout *)CFDataGetBytePtr(uchrDataRef), keyCode, kUCKeyActionDown, [self carbonModifierFromCocoaModifier:[event modifierFlags]], LMGetKbdType(), kUCKeyTranslateNoDeadKeysMask, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
			returnString = [NSString stringWithCharacters:unicodeString length:1];
	
			if (err != noErr) {
				returnString = [NSString stringWithString:[event charactersIgnoringModifiers]];
			}
			
			
		} else {
			returnString = [NSString stringWithString:[event charactersIgnoringModifiers]];
		}
	}
	
	return returnString;
}


- (NSString *)plainKeyStringFromEvent:(NSEvent *)event
{
	NSString *returnString;
	NSInteger keyCode = [event keyCode];
	
	if (keyCode == 0x7A) returnString = @"F1";
	else if (keyCode == 0x78) returnString = @"F2";
	else if (keyCode == 0x63) returnString = @"F3";
	else if (keyCode == 0x76) returnString = @"F4";
	else if (keyCode == 0x60) returnString = @"F5";
	else if (keyCode == 0x61) returnString = @"F6";
	else if (keyCode == 0x62) returnString = @"F7";
	else if (keyCode == 0x64) returnString = @"F8";
	else if (keyCode == 0x65) returnString = @"F9";
	else if (keyCode == 0x6D) returnString = @"F10";
	else if (keyCode == 0x67) returnString = @"F11";
	else if (keyCode == 0x6F) returnString = @"F12";
	else if (keyCode == 0x69) returnString = @"F13";
	else if (keyCode == 0x6B) returnString = @"F14";
	else if (keyCode == 0x71) returnString = @"F15";
	else if (keyCode == 0x6A) returnString = @"F16";
	else if (keyCode == 0x40) returnString = @"F17";
	else if (keyCode == 0x4F) returnString = @"F18";
	else if (keyCode == 0x50) returnString = @"F19";
	else
		returnString = [self menuItemKeyStringFromEvent:event];
	
	return [returnString uppercaseString];
}


- (NSString *)plainModifierStringFromEvent:(NSEvent *)event
{
	NSMutableString *returnString = [NSMutableString stringWithString:@""];
	NSInteger modifier = [event modifierFlags];
	
	if (modifier & NSCommandKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2318]];
	}
	
	if (modifier & NSAlternateKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2325]];
	}
	
	if (modifier & NSControlKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2303]];
	}
	
	if (modifier & NSShiftKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x21E7]];
	}	
	
	return returnString;
}


- (NSUInteger)carbonModifierFromCocoaModifier:(NSUInteger)cocoaModifier
{
	NSUInteger carbonModifier = 0;
	if (cocoaModifier & NSShiftKeyMask) carbonModifier |= shiftKey;
	if (cocoaModifier & NSControlKeyMask) carbonModifier |= controlKey;
	if (cocoaModifier & NSCommandKeyMask) carbonModifier |= cmdKey;
	if (cocoaModifier & NSAlternateKeyMask) carbonModifier |= optionKey;
	
	return carbonModifier;
}


@end
