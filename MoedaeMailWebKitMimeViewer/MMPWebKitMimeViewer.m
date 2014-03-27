//
//  MMPWebKitMimeViewer.m
//  MoedaeMailWebKitMimeViewer
//
//  Created by Taun Chapman on 02/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MMPWebKitMimeViewer.h"
#import <WebKit/WebKit.h>

#pragma message "ToDo: handle preferences for images, fonts etc"

@implementation MMPWebKitMimeViewer

/*
 {(
 "TEXT/XSL",
 "APPLICATION/RSS+XML",
 "APPLICATION/VND.WAP.XHTML+XML",
 "TEXT/HTML",
 "APPLICATION/X-WEBARCHIVE",
 "APPLICATION/X-FTP-DIRECTORY",
 "TEXT/JSCRIPT",
 "APPLICATION/X-JAVASCRIPT",
 "MULTIPART/X-MIXED-REPLACE",
 "TEXT/ECMASCRIPT",
 "TEXT/XML",
 "APPLICATION/ECMASCRIPT",
 "APPLICATION/XHTML+XML",
 "TEXT/JAVASCRIPT1.3",
 "TEXT/JAVASCRIPT",
 "APPLICATION/JSON",
 "APPLICATION/JAVASCRIPT",
 "APPLICATION/ATOM+XML",
 "TEXT/PLAIN",
 "TEXT/JAVASCRIPT1.2",
 "TEXT/",
 "IMAGE/SVG+XML",
 "APPLICATION/XML",
 "TEXT/JAVASCRIPT1.1",
 "TEXT/LIVESCRIPT"
 )}

 */
+(NSSet*) contentTypes {
    NSArray* mimeTypesLower = [WebView MIMETypesShownAsHTML];
    NSMutableSet* upperMimeSet = [NSMutableSet setWithCapacity: mimeTypesLower.count];
    for (NSString* mime in mimeTypesLower) {
        [upperMimeSet addObject: [mime uppercaseString]];
    }
//    [upperMimeSet removeObject: @"TEXT/PLAIN"];
    
    return [upperMimeSet copy];
//    return [NSSet setWithObjects:@"TEXT/PLAIN", @"TEXT/HTML", @"TEXT/ENRICHED", @"APPLICATION/MSWORD",nil];
}
#pragma message "ToDo: fix encoding"
-(void) loadData {
    
    WebFrame* mainFrame = [(WebView*)self.mimeView mainFrame];
    
    NSString* mimeType = [NSString stringWithFormat: @"%@/%@", self.node.type, self.node.subtype];
    
    NSData* nodeData = self.node.decoded;
    
    if ([[mimeType uppercaseString] isEqualToString: @"TEXT/PLAIN"]) {
        NSString* style = [NSString stringWithFormat: @"style=\"white-space: pre-wrap; white-space: -moz-pre-wrap !important; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\""];
        NSString* plainText = [[NSString alloc] initWithData: nodeData encoding: 4];
        NSString* preFormatted = [NSString stringWithFormat: @"<pre %@>%@</pre>",style, plainText];
        nodeData = [preFormatted dataUsingEncoding: NSUTF8StringEncoding];
    }
    
//    NSString* charset = self.node.charset;
    
    [mainFrame loadData: nodeData MIMEType: mimeType textEncodingName: @"utf-8" baseURL: nil];
    
//    [[mainFrame frameView] setAllowsScrolling: NO];
    
    [self setNeedsUpdateConstraints: YES];
}

-(void) createSubviews {
    NSSize subStructureSize = self.frame.size;
    
    WebView* nodeView = [[WebView alloc] initWithFrame: NSMakeRect(0, 0, subStructureSize.width, subStructureSize.height) frameName: @"MMPWebKitFrame" groupName: nil];
    [nodeView setFrameLoadDelegate: self];
    [[[nodeView mainFrame] frameView] setAllowsScrolling: NO];
    // View in nib is min size. Therefore we can use nib dimensions as min when called from awakeFromNib
//    [nodeView setMinSize: NSMakeSize(subStructureSize.width, subStructureSize.height)];
//    [nodeView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
//    [nodeView setVerticallyResizable: YES];
    
    // No horizontal scroll version
    //    [rawMime setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: NSViewWidthSizable];
    //
    //    [[rawMime textContainer] setContainerSize: NSMakeSize(subStructureSize.width, FLT_MAX)];
    //    [[rawMime textContainer] setWidthTracksTextView: YES];
    
    // Horizontal resizable version
//    [nodeView setHorizontallyResizable: YES];
    //    [rawMime setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
    
//    [[nodeView textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
//    [[nodeView textContainer] setWidthTracksTextView: YES];
    //    [self addSubview: nodeView];
    
    //    [nodeView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    //    NSDictionary *views = NSDictionaryOfVariableBindings(self, rawMime);
    
    //    [self setContentCompressionResistancePriority: NSLayoutPriorityFittingSizeCompression-1 forOrientation: NSLayoutConstraintOrientationVertical];
    //NSLayoutPriorityDefaultHigh
    CGFloat borderWidth = 0.0;
    [nodeView setWantsLayer: YES];
    CALayer* rawLayer = nodeView.layer;
    [rawLayer setBorderWidth: borderWidth];
    [rawLayer setBorderColor: [[NSColor blueColor] CGColor]];
    
    
    CALayer* myLayer = self.layer;
    [myLayer setBorderWidth: borderWidth*2];
    [myLayer setBorderColor: [[NSColor redColor] CGColor]];
    
    self.mimeView = nodeView;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector: @selector(viewFrameChanged:) name: NSViewFrameDidChangeNotification object: self.mimeView];
    
    [self loadData];
    
    [super createSubviews];
}

-(void) dealloc {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    [(WebView*)(self.mimeView) setFrameLoadDelegate: nil];
    [self setMimeView: nil];
}
#pragma mark - WebFrameLoadDelegate
#pragma mark - Fixes for Autolayout full page view
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (self.window) {
        [self invalidateIntrinsicContentSize];
    } else {
//        NSLog(@"No Window");
    }
}
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (self.window) {
        [self invalidateIntrinsicContentSize];
    } else {
//        NSLog(@"No Window");
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    self.loadingDidFinish = YES;
    
    if (self.window) {
        [self invalidateIntrinsicContentSize];
    } else {
//        NSLog(@"No Window");
    }
}
/* get the document size after fully loaded */
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    self.loadingDidFinish = YES;
    
    if (self.window) {
        [self invalidateIntrinsicContentSize];
    } else {
//        NSLog(@"No Window");
    }
}

/* keep the document from being clipped by the automatic internal scrollview */
-(NSSize) intrinsicContentSize {
    NSSize newSize = NSMakeSize(NSViewNoInstrinsicMetric, NSViewNoInstrinsicMetric);
    
    if (self.loadingDidFinish) {
        CGFloat height = self.bounds.size.height;
        CGFloat width = self.bounds.size.width;
        
        // set default value
        
        NSView* docView = [[[(WebView*)self.mimeView mainFrame] frameView] documentView];
        if (docView) {
            CGFloat docHeight = docView.frame.size.height;
            CGFloat docWidth = docView.frame.size.width;
            
            if (docHeight > 0) {
                height = docHeight;
            }
            
            if (docWidth > width) {
                width = docWidth + 20.0;
            } else {
                width = NSViewNoInstrinsicMetric;
            }
        }
        newSize = NSMakeSize(width, height);
    }
    
    return newSize;
}
/* update intrinsic size during view resizing */
-(void) viewFrameChanged:(NSView *)view {
    WebFrame* mainFrame = [(WebView*)self.mimeView mainFrame];
    NSView* docView = [[[(WebView*)self.mimeView mainFrame] frameView] documentView];
    CGFloat docWidth = docView.frame.size.width;
    CGFloat myWidth = self.frame.size.width;
    
    if (docWidth > (myWidth+50)) {
        [self invalidateIntrinsicContentSize];
//        [[mainFrame frameView] setAllowsScrolling: YES];
//        NSScrollView* scroller = [docView enclosingScrollView];
//        [scroller setHasVerticalScroller: NO];
//        [scroller setVerticalScroller: nil];
        
    } else {
//        [[mainFrame frameView] setAllowsScrolling: NO];
    }

}

@end
