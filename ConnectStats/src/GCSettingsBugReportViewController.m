//  MIT Licence
//
//  Created on 19/01/2013.
//
//  Copyright (c) 2013 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "GCSettingsBugReportViewController.h"
@import RZExternal;
#import "GCActivitiesCacheManagement.h"
#import "GCActivitiesOrganizer.h"
#import "GCAppGlobal.h"
#import "GCService.h"
#import "GCViewConfig.h"
#import "GCSettingsBugReport.h"

#define BUG_FILENAME @"bugreport.zip"
#define BUG_NO_COMMON_ID @"-1"

@interface GCSettingsBugReportViewController ()
@property (nonatomic,retain) GCSettingsBugReport * report;
@end

@implementation GCSettingsBugReportViewController
-(void)dealloc{
    [_report release];
    [_webView release];
    [_parent release];
    [_hud release];

    [super dealloc];
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.webView.frame = self.view.frame;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.webView.frame = self.view.frame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.
	UIWebView *contentView	= [[UIWebView alloc] initWithFrame: self.view.frame];
    contentView.delegate = self;

    self.report = [GCSettingsBugReport bugReport];
    self.report.includeErrorFiles = self.includeErrorFiles;
    self.report.includeActivityFiles = self.includeActivityFiles;
    
    self.webView = contentView;

    [contentView loadRequest:self.report.urlRequest];

    [self.view addSubview:contentView];
    self.hud =[MBProgressHUD showHUDAddedTo:contentView animated:YES];
    self.hud.labelText = @"Preparing Report";

	[contentView release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    RZLog(RZLogWarning, @"memory warning %@", [RZMemory formatMemoryInUse]);
    // Dispose of any resources that can be recreated.
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
-(void)webViewDidFinishLoad:(UIWebView *)aWebView{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.report cleanupAndReset];
    NSString * commonid = [aWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('commonid').value"];
    if (commonid.integerValue>1) {
        [GCAppGlobal configSet:CONFIG_BUG_COMMON_ID stringVal:commonid];
        [GCAppGlobal saveSettings];
    }

    [self.hud hide:YES];
    if (self.parent) {
        [(self.parent).tableView reloadData];
    }
}

@end
