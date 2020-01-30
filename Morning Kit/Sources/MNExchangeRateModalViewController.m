//
//  MNExchangeRateModalViewController_iPhone.m
//  Morning Kit
//
//  Created by Yongbin Bae on 13. 5. 10..
//  Copyright (c) 2013년 Yooii Studios. All rights reserved.
//

#import "MNExchangeRateModalViewController.h"
#import "MNTheme.h"
#import "MNExchangeRateParser.h"
#import "MNLanguage.h"
#import "MNKeyboardHideButtonMaker.h"

@interface MNExchangeRateModalViewController ()

@end

@implementation MNExchangeRateModalViewController
{
    NSString *prevBaseCountryCode;
    NSString *prevTargetCountryCode;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//        self.hideKeyboardButton.alpha = 0;
//        [self.hideKeyboardButton addTarget:self action:@selector(doneWithNumberPad) forControlEvents:UIControlEventTouchUpInside];
        
        // 키보드 숨김 버튼을 UITextField에 연결시키기
        // 악세사리뷰(외부 프로젝트로 해결해서 가져온 코드)
        UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, self.hideKeyboardButton.frame.size.height)];
        self.baseCurrency.inputAccessoryView = inputAccessoryView;
        
        UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [hideButton setImage:[UIImage imageNamed:@"hide_icon_keypad"] forState:UIControlStateNormal];
        CGRect hideButtonFrame = self.hideKeyboardButton.frame;
        hideButtonFrame.origin.y = 0;
        hideButton.frame = hideButtonFrame;
        [inputAccessoryView addSubview:hideButton];
        
        [hideButton addTarget:self action:@selector(doneWithNumberPad) forControlEvents:UIControlEventTouchUpInside];
        
        [self.hideKeyboardButton removeFromSuperview];
        
    }
    [self initUI];
    
    prevBaseCountryCode = self.widgetDictionary[KEY_BASE_COUNTRY];
    prevTargetCountryCode = self.widgetDictionary[KEY_TARGET_COUNTRY];
    
//    self.baseCurrency.inputAccessoryView = aNavBarWithDoneButton;
    
    self.reverseLabel.text = MNLocalizedString(@"exchange_rate_switch_countries", @"환율 순서 변경");
    [self setThemeColor];
    [self parseExchangeRateWithRevise:NO];
}

- (void)initUI
{
    NSString *baseCountryCode = self.widgetDictionary[KEY_BASE_COUNTRY];
    NSString *targetCountryCode = self.widgetDictionary[KEY_TARGET_COUNTRY];
    NSString *base_currency = [self.widgetDictionary objectForKey:KEY_BASE_CURRENCY];
    
    // 저장 값이 있는 지 체크
    if (baseCountryCode && targetCountryCode)
    {
        self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:baseCountryCode];
        self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:targetCountryCode];
    }
    else
    {
        // 없다면 마지막 설정 값이 있는지 체크
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *latestSettings = [defaults objectForKey:@"exchange_rate_latest_setting"];
        
        if (latestSettings)
        {
            baseCountryCode = latestSettings[KEY_SHARED_BASE_COUNTRY];
            targetCountryCode = latestSettings[KEY_SHARED_TARGET_COUNTRY];
            base_currency = latestSettings[KEY_SHARED_BASE_CURRENCY];
            
            self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:baseCountryCode];
            self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:targetCountryCode];
            
            [self.widgetDictionary setObject:baseCountryCode forKey:KEY_BASE_COUNTRY];
            [self.widgetDictionary setObject:targetCountryCode forKey:KEY_TARGET_COUNTRY];
            [self.widgetDictionary setObject:base_currency forKey:KEY_BASE_CURRENCY];
        }
        else
        {
            // Default Country
            
            //한국어: 1000원 -> 달러
            //일본어: 100엔 -> 달러
            //간체: 10위엔 -> 달러
            //번체: 100대만달러 -> 달러
            //영어: $1 -> 유로
            
            if ([[MNLanguage getCurrentLanguage] isEqualToString:@"ko"])
            { // 한국어
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"KRW"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                [self.widgetDictionary setObject:@"1000" forKey:KEY_BASE_CURRENCY];
            }
            else if ([[MNLanguage getCurrentLanguage] isEqualToString:@"en"])
            { // 영어
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"EUR"];
                [self.widgetDictionary setObject:@"1" forKey:KEY_BASE_CURRENCY];
            }
            else if ([[MNLanguage getCurrentLanguage] isEqualToString:@"ja"])
            { // 일본어
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"JPY"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                [self.widgetDictionary setObject:@"100" forKey:KEY_BASE_CURRENCY];
                
            }
            else if ([[MNLanguage getCurrentLanguage] isEqualToString:@"zh-Hans"])
            { // 중국어 간체
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"CNY"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                [self.widgetDictionary setObject:@"10" forKey:KEY_BASE_CURRENCY];
            }
            else if ([[MNLanguage getCurrentLanguage] isEqualToString:@"zh-Hant"])
            { // 중국어 본체
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"TWD"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                [self.widgetDictionary setObject:@"100" forKey:KEY_BASE_CURRENCY];
            }
            else if([[MNLanguage getCurrentLanguage] isEqualToString:@"ru"]) {
                // 러시아어
                // 러시안 루블 RUB  USD
                self.baseCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"RUB"];
                self.targetCountry = [MNExchangeRateCountryLoader countryWithCountryCode:@"USD"];
                [self.widgetDictionary setObject:@"100" forKey:KEY_BASE_CURRENCY];

            }
            [self.widgetDictionary setObject:self.baseCountry.currencyUnitCode forKey:KEY_BASE_COUNTRY];
            [self.widgetDictionary setObject:self.targetCountry.currencyUnitCode forKey:KEY_TARGET_COUNTRY];
        }
    }
    
    base_currency = self.widgetDictionary[KEY_BASE_CURRENCY];
    
    self.targetLabel.text = self.targetCountry.currencyUnitCode;
    self.targetLabel.textColor = [MNTheme getMainFontUIColor];
    self.targetFlag.image = self.targetCountry.flag;
    
    self.baseLabel.text = self.baseCountry.currencyUnitCode;
    self.baseLabel.textColor = [MNTheme getMainFontUIColor];
    self.baseFlag.image = self.baseCountry.flag;
    
    long double base_currency_int = [base_currency doubleValue];
    if (base_currency == nil) {
        base_currency_int = 1;
    }
    
    self.baseCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithDouble:base_currency_int] Symbol:self.baseCountry.currencySymbol];
}

- (void)setThemeColor
{
    if ([MNTheme getCurrentlySelectedTheme] == MNThemeTypeClassicWhite ||
        [MNTheme getCurrentlySelectedTheme] == MNThemeTypeMirror ||
        [MNTheme getCurrentlySelectedTheme] == MNThemeTypePhoto ||
        [MNTheme getCurrentlySelectedTheme] == MNThemeTypeScenery ||
        [MNTheme getCurrentlySelectedTheme] == MNThemeTypeWaterLily)
    {
        self.view1.backgroundColor = UIColorFromHexCodeWithAlpha(0xcfcfcf, 0.6f);
        self.view2.backgroundColor = UIColorFromHexCodeWithAlpha(0xcfcfcf, 0.6f);
        self.view3.backgroundColor = UIColorFromHexCodeWithAlpha(0xcfcfcf, 0.6f);
        self.view4.backgroundColor = UIColorFromHexCodeWithAlpha(0xcfcfcf, 0.6f);
    }
    else
    {
        self.view1.backgroundColor = [MNTheme getForwardBackgroundUIColor];
        self.view2.backgroundColor = [MNTheme getForwardBackgroundUIColor];
        self.view3.backgroundColor = [MNTheme getForwardBackgroundUIColor];
        self.view4.backgroundColor = [MNTheme getForwardBackgroundUIColor];
    }
    
    self.view.backgroundColor = [MNTheme getBackwardBackgroundUIColor];
    self.targetLabel.textColor = [MNTheme getMainFontUIColor];
    self.baseLabel.textColor = [MNTheme getMainFontUIColor];
    self.reverseLabel.textColor = [MNTheme getMainFontUIColor];
    self.baseCurrency.textColor = [MNTheme getMainFontUIColor];
    self.targetCurrency.textColor = [MNTheme getMainFontUIColor];
}

- (void)parseExchangeRateWithRevise:(BOOL)revise
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
//        NSString *base_currency = [self.widgetDictionary objectForKey:KEY_BASE_CURRENCY];
        self.exchangeRate = [MNExchangeRateParser getExchangeRateWithBase:self.baseCountry.currencyUnitCode Target:self.targetCountry.currencyUnitCode];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.targetLabel.text = self.targetCountry.currencyUnitCode;
            self.targetFlag.image = self.targetCountry.flag;
            
            self.baseLabel.text = self.baseCountry.currencyUnitCode;
            self.baseFlag.image = self.baseCountry.flag;
            
            NSString *base_currency = self.baseCurrency.text;
            
            
            long double base_currency_int = [[self numberWithCurrencyString:base_currency Symbol:self.baseCountry.currencySymbol] doubleValue];
            if (base_currency == nil) {
                base_currency_int = 1;
            } 
            long double target_currency_double = base_currency_int * self.exchangeRate;
            
            if (revise)
            {
                if (base_currency_int == 1)
                {
                    while (target_currency_double < 0.1)
                    {
                        base_currency_int *= 10;
                        target_currency_double *= 10;
                    }
                }
            }
//            self.baseCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithInt:base_currency_int] Symbol:self.baseCountry.currencySymbol];
            
            if (self.exchangeRate == MNExchangeRateParseErr)
                self.targetCurrency.text = MNLocalizedString(@"no_network_connection", @"no_network");
            else
                self.targetCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithDouble:target_currency_double] Symbol:self.targetCountry.currencySymbol];
        });
    });
}

- (void)doneButtonClicked
{
    if (self.baseCurrency.isEditing) {
//        [self.baseCurrency endEditing:YES];
        [self doneWithNumberPad];
    }
    
    NSNumber *temp = [self numberWithCurrencyString:self.baseCurrency.text Symbol:self.baseCountry.currencySymbol];
    
    // 최근 설정으로 저장
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *latestSettings = [NSMutableDictionary dictionary];
    
    if (temp.doubleValue == 0)
    {
        temp = [(NSMutableDictionary *)[userDefaults objectForKey:@"exchange_rate_latest_setting"] objectForKey:KEY_SHARED_BASE_CURRENCY];
        if (temp == nil) {
            temp = [NSNumber numberWithDouble:0];
        }
    }
    
    [self.widgetDictionary setObject:temp forKey:KEY_BASE_CURRENCY];
    [latestSettings setObject:self.widgetDictionary[KEY_BASE_COUNTRY] forKey:KEY_SHARED_BASE_COUNTRY];
    [latestSettings setObject:self.widgetDictionary[KEY_TARGET_COUNTRY] forKey:KEY_SHARED_TARGET_COUNTRY];
    [latestSettings setObject:self.widgetDictionary[KEY_BASE_CURRENCY] forKey:KEY_SHARED_BASE_CURRENCY];
    
    [userDefaults setObject:latestSettings forKey:@"exchange_rate_latest_setting"];
    
    [super doneButtonClicked];
}

- (void)cancelButtonClicked
{
    if (prevBaseCountryCode) {
        self.widgetDictionary[KEY_BASE_COUNTRY] = prevBaseCountryCode;
        self.widgetDictionary[KEY_TARGET_COUNTRY] = prevTargetCountryCode;
    }
    
    [super cancelButtonClicked];
}

- (IBAction)editingDidBegin:(id)sender {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.hideKeyboardButton.alpha = 1;
        CGRect currentFrame = self.hideKeyboardButton.frame;
        self.hideKeyboardButton.frame = CGRectMake(currentFrame.origin.x,
                                                   self.view.frame.size.height - currentFrame.size.height,
                                                   currentFrame.size.width,
                                                   currentFrame.size.height);
        
        [UIView animateWithDuration:0.25f animations:^{
            self.hideKeyboardButton.frame = CGRectMake(currentFrame.origin.x,
                                                       self.view.frame.size.height - KEYBOARD_HEIGHT - currentFrame.size.height,
                                                       currentFrame.size.width,
                                                       currentFrame.size.height);
        }];
    }
    
    long double baseCurrency = [[self numberWithCurrencyString:self.baseCurrency.text Symbol:self.baseCountry.currencySymbol] doubleValue];
    if ((int)(baseCurrency * 100) % 100 == 0)
        self.baseCurrency.text = [NSString stringWithFormat:@"%d", (int)baseCurrency];
    else
        self.baseCurrency.text = [NSString stringWithFormat:@"%0.2Lf", baseCurrency];
    
    if (baseCurrency == 0) {
        self.baseCurrency.text = @"";
    }
    
    long double target_currency_double = baseCurrency * self.exchangeRate;
    
    if (self.exchangeRate == MNExchangeRateParseErr)
        self.targetCurrency.text = MNLocalizedString(@"no_network_connection", @"no_network");
    else
        self.targetCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithDouble:target_currency_double] Symbol:self.targetCountry.currencySymbol];
}

- (IBAction)onRightEditTouched:(id)sender
{
    [self.baseCurrency performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1f];
}

- (IBAction)onEditing:(id)sender
{
    long double base_currency_int = [self.baseCurrency.text doubleValue];
    long double target_currency_double = base_currency_int * self.exchangeRate;
    
    NSString *targetCurrencyStr = [self currencyStringWithNumber:[NSNumber numberWithDouble:target_currency_double] Symbol:self.targetCountry.currencySymbol];
    
    
    if (self.exchangeRate == MNExchangeRateParseErr)
        self.targetCurrency.text = MNLocalizedString(@"no_network_connection", @"no_network");
    else
        self.targetCurrency.text = targetCurrencyStr;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self textFieldDidEndEditing:textField];
//    [self.baseCurrency endEditing:YES];
    [self.baseCurrency endEditing:YES];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.widgetDictionary[KEY_BASE_CURRENCY] = self.baseCurrency.text;
    self.baseCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithDouble:[self.baseCurrency.text doubleValue]] Symbol:self.baseCountry.currencySymbol];
    
    /*
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGRect currentFrame = self.hideKeyboardButton.frame;
        
        self.hideKeyboardButton.frame = CGRectMake(currentFrame.origin.x,
                                                   currentFrame.origin.y + KEYBOARD_HEIGHT + currentFrame.size.height,
                                                   currentFrame.size.width,
                                                   currentFrame.size.height);
        self.hideKeyboardButton.alpha = 0;
    }
     */
    
//    NSLog(@"TextFieldDidEndEditing");
}

- (void)doneWithNumberPad
{
    [self.baseCurrency endEditing:YES];
//
//    self.widgetDictionary[KEY_BASE_CURRENCY] = self.baseCurrency.text;
//    self.baseCurrency.text = [self currencyStringWithNumber:[NSNumber numberWithDouble:[self.baseCurrency.text doubleValue]] Symbol:self.baseCountry.currencySymbol];
//    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//        CGRect currentFrame = self.hideKeyboardButton.frame;
//        
//        self.hideKeyboardButton.frame = CGRectMake(currentFrame.origin.x,
//                                                   currentFrame.origin.y + KEYBOARD_HEIGHT + currentFrame.size.height,
//                                                   currentFrame.size.width,
//                                                   currentFrame.size.height);
//        self.hideKeyboardButton.alpha = 0;
//    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    for (UITouch *touch in touches) {
        switch (touch.view.tag) {
            case 20:
            {
                MNERCountrySelectTabBarControllerViewController *modalController;
                modalController = [[MNERCountrySelectTabBarControllerViewController alloc] init];
                modalController.selectDelegate = self;
                modalController.Target = @"BASE";
                
                UINavigationController *modalNavCont = [[UINavigationController alloc] initWithRootViewController:modalController];
                [modalNavCont.navigationBar setBarStyle:UIBarStyleBlack];
                [self presentViewController:modalNavCont animated:YES completion:nil];                
                break;
            }
            case 21:
            {
                MNERCountrySelectTabBarControllerViewController *modalController;
                modalController = [[MNERCountrySelectTabBarControllerViewController alloc] init];
                modalController.selectDelegate = self;
                modalController.Target = @"TARGET";
                
                UINavigationController *modalNavCont = [[UINavigationController alloc] initWithRootViewController:modalController];
                [modalNavCont.navigationBar setBarStyle:UIBarStyleBlack];
                [self presentViewController:modalNavCont animated:YES completion:nil];
                
                break;
            }
            case 23:
            {
                //Swap countries
                [self.baseCurrency endEditing:YES];
                self.widgetDictionary[KEY_BASE_COUNTRY] = self.targetCountry.currencyUnitCode;
                self.widgetDictionary[KEY_TARGET_COUNTRY] = self.baseCountry.currencyUnitCode;
                [self parseExchangeRateWithRevise:YES];
                [self reviseFloatingPoint];
                [self initUI];
                break;
            }
            default:
                break;
        }
    }
}

- (void)reviseFloatingPoint
{
    
}

- (NSString *)currencyStringWithNumber:(NSNumber *)number Symbol:(NSString *)symbol
{
    NSString *str;
    
    NSNumberFormatter *formmater = [[NSNumberFormatter alloc] init];
    if (((int)(number.doubleValue*100)%100 == 0))
        [formmater setMinimumFractionDigits:0];
    else
        [formmater setMinimumFractionDigits:2];
    [formmater setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formmater setCurrencySymbol:symbol];
    
    str = [formmater stringFromNumber:number];
    
    return str;
}

- (NSNumber *)numberWithCurrencyString:(NSString *)string Symbol:(NSString *)symbol
{
    NSNumber *num;
    
    NSNumberFormatter *formmater = [[NSNumberFormatter alloc] init];
    if (((int)(num.doubleValue*100)%100 == 0))
        [formmater setMinimumFractionDigits:0];
    else
        [formmater setMinimumFractionDigits:2];
    [formmater setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formmater setCurrencySymbol:symbol];
    
    num = [formmater numberFromString:string];
    
    return num;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBaseLabel:nil];
    [self setTargetLabel:nil];
    [self setBaseCurrency:nil];
    [self setTargetCurrency:nil];
    [self setReverseButton:nil];
    [self setReverseLabel:nil];
    [self setView1:nil];
    [self setView2:nil];
    [self setView3:nil];
    [self setView4:nil];
    [super viewDidUnload];
}

#pragma mark - Country Select Delegate

- (void)countrySelected:(NSString *)code Target:(NSString *)target
{
    if ([target isEqualToString:@"BASE"])
    {
        self.widgetDictionary[KEY_BASE_COUNTRY] = code;
        [self initUI];
        [self parseExchangeRateWithRevise:NO];
    }
    else if ([target isEqualToString:@"TARGET"])
    {
        self.widgetDictionary[KEY_TARGET_COUNTRY] = code;
        [self initUI];
        [self parseExchangeRateWithRevise:NO];
    }
}

#pragma mark - rotate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    }
    return NO;
}


// for over iOS 6.0
- (BOOL)shouldAutorotate {
    return YES;
}


// Tell the system which initial orientation we want to have
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
    
}


// Tell the system what we support
-(NSUInteger)supportedInterfaceOrientations
{
    // return UIInterfaceOrientationMaskLandscapeRight;
    // return UIInterfaceOrientationMaskAll;
    return UIInterfaceOrientationMaskPortrait;
}

@end
