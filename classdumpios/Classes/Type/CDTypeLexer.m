// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDTypeLexer.h"

#import "NSScanner-CDExtensions.h"

#ifdef DEBUG
static BOOL debug = NO;
#else
static BOOL debug = NO;
#endif

static NSString *CDTypeLexerStateName(CDTypeLexerState state)
{
    switch (state) {
        case CDTypeLexerState_Normal:        return @"Normal";
        case CDTypeLexerState_Identifier:    return @"Identifier";
        case CDTypeLexerState_TemplateTypes: return @"Template";
    }
}

@implementation CDTypeLexer
{
    NSScanner *_scanner;
    CDTypeLexerState _state;
    NSString *_lexText;
    
    BOOL _shouldShowLexing;
}

- (id)initWithString:(NSString *)string;
{
    if ((self = [super init])) {
        if (!string){
            VerboseLog(@"%s NSScanner initWithString: %@", _cmds, string);
            return nil;
        }
        _scanner = [[NSScanner alloc] initWithString:string];
        [_scanner setCharactersToBeSkipped:nil];
        _state = CDTypeLexerState_Normal;
        _shouldShowLexing = debug;
    }

    return self;
}

#pragma mark -

- (void)setState:(CDTypeLexerState)newState;
{
    if (_state != newState){
        VerboseLog(@"CDTypeLexer - changing state from %lu (%@) to %lu (%@)", _state, CDTypeLexerStateName(_state), newState, CDTypeLexerStateName(newState));
    }
    _state = newState;
}

- (NSString *)string;
{
    return [_scanner string];
}

- (int)scanNextToken;
{
    NSString *str;
    unichar ch;

    _lexText = nil;

    if ([_scanner isAtEnd]) {
        if (_shouldShowLexing)                       DLog(@"%s [state=%lu], token = TK_EOS", _cmds, _state);
        return TK_EOS;
    }

    if (_state == CDTypeLexerState_TemplateTypes) {
        // Skip whitespace, scan '<', ',', '>'.  Everything else is lumped together as a string.
        [_scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        if ([_scanner scanString:@"<" intoString:NULL]) {
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = %d '%c'", _cmds, _state, '<', '<');
            return '<';
        }

        if ([_scanner scanString:@">" intoString:NULL]) {
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = %d '%c'", _cmds, _state, '>', '>');
            return '>';
        }

        if ([_scanner scanString:@"," intoString:NULL]) {
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = %d '%c'", _cmds, _state, ',', ',');
            return ',';
        }

        if ([_scanner my_scanCharactersFromSet:[NSScanner cdTemplateTypeCharacterSet] intoString:&str]) {
            _lexText = str;
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = TK_TEMPLATE_TYPE (%@)", _cmds, _state, _lexText);
            return TK_TEMPLATE_TYPE;
        }

        DLog(@"Ooops, fell through in template types state.");
    } else if (_state == CDTypeLexerState_Identifier) {
        NSString *identifier;

        //DLog(@"Scanning in identifier state.");
        [_scanner setCharactersToBeSkipped:nil];

        if ([_scanner scanIdentifierIntoString:&identifier]) {
            _lexText = identifier;
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = TK_IDENTIFIER (%@)", _cmds, _state, _lexText);
            _state = CDTypeLexerState_Normal;
            return TK_IDENTIFIER;
        }
    } else {
        [_scanner setCharactersToBeSkipped:nil];

        if ([_scanner scanString:@"\"" intoString:NULL]) {
            if ([_scanner scanUpToString:@"\"" intoString:&str])
                _lexText = str;
            else
                _lexText = @"";

            [_scanner scanString:@"\"" intoString:NULL];
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = TK_QUOTED_STRING (%@)", _cmds, _state, _lexText);
            return TK_QUOTED_STRING;
        }

        if ([_scanner my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str]) {
            _lexText = str;
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = TK_NUMBER (%@)", _cmds, _state, _lexText);
            return TK_NUMBER;
        }

        if ([_scanner scanCharacter:&ch]) {
            if (_shouldShowLexing)                   DLog(@"%s [state=%lu], token = %d '%c'", _cmds, _state, ch, ch);
            return ch;
        }
    }

    if (_shouldShowLexing)                           DLog(@"%s [state=%lu], token = TK_EOS", _cmds, _state);

    return TK_EOS;
}

- (unichar)peekChar;
{
    return [_scanner peekChar];
}

- (NSString *)remainingString;
{
    return [[_scanner string] substringFromIndex:[_scanner scanLocation]];
}

- (NSString *)peekIdentifier;
{
    if (![_scanner string]){
        VerboseLog(@"%s NSScanner initWithString: %@", _cmds, [_scanner string]);
    }
    NSScanner *peekScanner = [[NSScanner alloc] initWithString:[_scanner string]];
    [peekScanner setScanLocation:[_scanner scanLocation]];

    NSString *identifier;
    if ([peekScanner scanIdentifierIntoString:&identifier]) {
        return identifier;
    }

    return nil;
}

@end
