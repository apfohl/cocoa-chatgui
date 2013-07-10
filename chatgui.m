#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <unistd.h>
#include <string.h>

static int _infd, _outfd;

@interface GuiWindow : NSObject

@property (nonatomic, strong) NSMenu *menubar;
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) NSButton *button;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSTextField *textField;

- (IBAction)doIt:(id)sender;
+ (void)threadDo:(id)sender;

@end

@implementation GuiWindow

- (id)init
{
	if (self = [super init])
	{
		NSString *appName = [[NSProcessInfo processInfo] processName];
		NSString *quitTitle = [@"Quit " stringByAppendingString:appName];

		self.menubar = [[NSMenu new] autorelease];
		NSMenuItem *appMenuItem = [[NSMenuItem new] autorelease];
		[self.menubar addItem:appMenuItem];
    
		NSMenu *appMenu = [[NSMenu new] autorelease];
		NSMenuItem *quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle
			action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
		[appMenu addItem:quitMenuItem];
		[appMenuItem setSubmenu:appMenu];

		self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 700, 500)
			styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
		[self.window center];
		[self.window setTitle:appName];
		[self.window makeKeyAndOrderFront:nil];

		self.button = [[NSButton alloc] initWithFrame:NSMakeRect(640, 0, 60, 30)];
		[self.button setTitle:@"send"];
		[self.button setKeyEquivalent:@"\r"];
		self.button.target = self;
		self.button.action = @selector(doIt:);
		[[self.window contentView] addSubview:self.button];

		self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 30, 700, 470)];
		[self.scrollView setHasVerticalScroller:YES];
		[self.scrollView setAcceptsTouchEvents:YES];
		[self.scrollView setScrollsDynamically:YES];
		self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 30, 700, 470)];
		[self.textView setEditable:NO];
		[self.scrollView setDocumentView:self.textView];
		[[self.window contentView] addSubview:self.scrollView];
		[self.window makeFirstResponder:self.textView];

		self.textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 640, 30)];
		[[self.window contentView] addSubview:self.textField];
	}

	return self;
}

- (IBAction)doIt:(id)sender
{
	const char *str = [[[_textField stringValue] stringByAppendingString:@"\n"]
			cStringUsingEncoding:NSUTF8StringEncoding];
	write(_infd, str, strlen(str));
	[self.textField setStringValue:@""];
	[self.textField display];
}

+ (void)scrollToBottom:(NSScrollView *)scrollView
{
	NSPoint newScrollOrigin;

	if ([[scrollView documentView] isFlipped])
	{
        newScrollOrigin = NSMakePoint(0.0, NSMaxY([[scrollView documentView] frame])
				- NSHeight([[scrollView contentView] bounds]));
    } else {
        newScrollOrigin = NSMakePoint(0.0, 0.0);
    }
 
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}

+ (void)threadDo:(id)sender
{
	char buf[1025];
	int r = 0;

	while((r = read(_outfd, buf, 1024)) > 0)
	{
		buf[r] = '\0';
		[[[[sender textView] textStorage] mutableString]
			appendString:[[NSString class]
			stringWithCString:buf
			encoding:NSUTF8StringEncoding]];
		[[sender class] scrollToBottom:[sender scrollView]];
	}
}

@end

void setup_chat_window()
{
	[NSAutoreleasePool new];
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

	GuiWindow *guiWindow = [[[GuiWindow alloc] init] autorelease];
	[NSApp setMainMenu:guiWindow.menubar];
    [NSApp activateIgnoringOtherApps:YES];

	[NSThread detachNewThreadSelector:@selector(threadDo:) toTarget:[guiWindow class] withObject:guiWindow];

    [NSApp run];
}

pid_t gui_start(int *infd, int *outfd)
{
	int inputPipe[2];
	int outputPipe[2];
	pid_t cpid;

	if (pipe(inputPipe) == -1)
	{
		perror("pipe");
		return -1;
	}

	if (pipe(outputPipe) == -1)
	{
		perror("pipe");
		return -1;
	}

	cpid = fork();
	switch(cpid)
	{
		case -1:
			perror("fork");
			return -1;

		case 0:
			/* sweet child in time */
			close(inputPipe[0]);
			close(outputPipe[1]);

			_infd = inputPipe[1];
			_outfd = outputPipe[0];

			setup_chat_window();

			close(inputPipe[1]);
			close(outputPipe[0]);
			return 0;

		default:
			close(inputPipe[1]);
			close(outputPipe[0]);
			*infd = inputPipe[0];
			*outfd = outputPipe[1];
	}

    return cpid;
}
