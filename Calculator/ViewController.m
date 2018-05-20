//
//  ViewController.m
//  Calculator
//
//  Created by moses on 2018/5/19.
//

#import "ViewController.h"
#import <sys/utsname.h>
#define ms_width [UIScreen mainScreen].bounds.size.width
#define ms_height [UIScreen mainScreen].bounds.size.height
#define ms_backgroundColor [UIColor colorWithWhite:0.95 alpha:1.0]
#define ms_iPhoneX ([UIScreen mainScreen].bounds.size.height == 812)
typedef enum {
    OperaTypeNone = 0,
    OperaTypeAddition = 1,//加
    OperaTypeSubtraction = 2,//减
    OperaTypeMultiplication = 3,//乘
    OperaTypeDivision = 4,//除
} OperaType;

@interface ViewController ()

@property (nonatomic, strong) UILabel *label; /**< 显示结果的label */
@property (nonatomic, copy) NSString *preText; /**< 前面的数 */
@property (nonatomic, copy) NSString *text; /**< 当前显示的数 */
@property (nonatomic, assign) OperaType operaType; /**< 点击了哪个运算符 */
@property (nonatomic, assign) BOOL equal; /**< 是否是刚点击完等于 */

@end

@implementation ViewController

static int maxLength = 9;// 最大长度

/**
 创建一个纯色图片
 */
- (UIImage *)createImageWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/**
 是否是iPad
 */
- (BOOL)iPad {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return [deviceString hasPrefix:@"iPad"];
}

/**
 将string每隔三位添加一个逗号
 */
- (NSString *)getCommaTextWithString:(NSString *)string {
    if ([string containsString:@"e"]) {
        return string;
    }
    BOOL sign = [string hasPrefix:@"-"];
    NSString *str = sign ? [string substringFromIndex:1] : string;
    BOOL FLOAT = [string containsString:@"."];
    NSString *str1 = FLOAT ? [str componentsSeparatedByString:@"."][0] : str;
    NSString *str2 = FLOAT ? [NSString stringWithFormat:@".%@", [str componentsSeparatedByString:@"."][1]] : @"";
    NSMutableString *mutableStr = [NSMutableString stringWithString:str1];
    for (int i = 3; i < 300; i += 3) {
        if (str1.length > i) {
            [mutableStr insertString:@"," atIndex:str1.length - i];
        } else {
            break;
        }
    }
    if (sign) [mutableStr insertString:@"-" atIndex:0];
    [mutableStr appendString:str2];
    return [NSString stringWithString:mutableStr];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ms_backgroundColor;
    // 添加计算结果label
    self.label = [[UILabel alloc] init];
    self.label.text = @"0";
    self.label.textAlignment = NSTextAlignmentRight;
    self.label.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.label.backgroundColor = ms_backgroundColor;
    self.label.font = [UIFont systemFontOfSize:48];
    self.label.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:self.label];
    [self clean];
    // (100-109) 0、1、2、3、4、5、6、7、8、9
    // 110、111、112、113、114、115、116、117
    //  . 、 + 、 - 、 x 、 ÷ 、del、 C 、 =
    
    // 添加计算器布局, 高度可随意伸缩
    CGFloat count = [self iPad] ? 1.1 : (ms_iPhoneX ? 1.5 : 1.3);
    UIView *view = [[NSBundle mainBundle] loadNibNamed:@"Calculator" owner:nil options:nil].firstObject;
    view.frame = CGRectMake(0, ms_height - ms_width * count - ms_iPhoneX * 34, ms_width, ms_width * count);
    [self.view addSubview:view];
    UIImage *image = [self createImageWithColor:ms_backgroundColor size:[view viewWithTag:101].frame.size];
    for (int i = 0; i < 18; i++) {
        UIButton *button = [view viewWithTag:100+i];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        if (i == 0) {
            UIImage *image = [self createImageWithColor:ms_backgroundColor size:button.frame.size];
            [button setBackgroundImage:image forState:(UIControlStateHighlighted)];
        } else if (i == 17) {
            UIImage *image = [self createImageWithColor:[UIColor brownColor] size:button.frame.size];
            [button setBackgroundImage:image forState:(UIControlStateHighlighted)];
        } else {
            [button setBackgroundImage:image forState:(UIControlStateHighlighted)];
        }
    }
    self.label.frame = CGRectMake(15, view.frame.origin.y - 75, ms_width - 30, 60);
    
    [self addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
    [self.label addGestureRecognizer:[[UIGestureRecognizer alloc] initWithTarget:self action:@selector(pasteAction)]];
}

/**
 text监听, 每次text变化, 都要改变label显示的内容
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"text"]) {
        if (self.text.length) {
            self.label.text = [self getCommaTextWithString:self.text];
        } else {
            self.label.text = @"0";
        }
    }
}

- (void)pasteAction {
    NSString *text = [self.label.text stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (![text isEqualToString:@"0"]) {
        [UIPasteboard generalPasteboard].string = text;
        NSLog(@"复制成功");
    }
}

/**
 所有按钮的点击事件
 */
- (void)buttonAction:(UIButton *)button {
    // (100-109) 0、1、2、3、4、5、6、7、8、9
    // 110、111、112、113、114、115、116、117
    //  . 、 + 、 - 、 x 、 ÷ 、del、 C 、 =
    switch (button.tag) {
        case 100:
            if (self.text.length == 0 || (self.text.length && self.text.doubleValue == 0)) {
                // 当没有输入小数点的时候, 如果只有一个0, 不允许继续输入0
                return;
            }
        case 101:
        case 102:
        case 103:
        case 104:
        case 105:
        case 106:
        case 107:
        case 108:
        case 109:{
            if (self.equal) {
                self.text = button.currentTitle;
            } else if ([[self.text stringByReplacingOccurrencesOfString:@"." withString:@""] stringByReplacingOccurrencesOfString:@"-" withString:@""].length < maxLength) {
                self.text = [self.text stringByAppendingString:button.currentTitle];
            }
            self.equal = NO;
        }break;
        case 110:{
            // 小数点
            if (self.text.length && !self.equal) {
                if (![self.text containsString:@"."] && ![self.text containsString:@"e"]) {
                    self.text = [self.text stringByAppendingString:@"."];
                }
            } else {
                self.text = @"0.";
            }
            self.equal = NO;
        }break;
        case 111:
        case 112:
        case 113:
        case 114:{
            self.equal = NO;
            // 如果之前没点击运算符, 则将text的值赋给preTest; 如果点击过运算符, (如果当前输入了数字, 则直接相当于点击了等于和当前点击的运算符, 否则更新运算符)
            if (self.operaType) {
                if (self.text.length) {
                    self.preText = [self calcultator];
                    self.text = @"";
                    self.label.text = [self getCommaTextWithString:self.preText];
                    self.operaType = (int)button.tag - 110;
                } else {
                    self.operaType = (int)button.tag - 110;
                }
            } else if (self.text.length) {
                self.operaType = (int)button.tag - 110;
                self.preText = self.text;
                self.text = @"";
                self.label.text = [self getCommaTextWithString:self.preText];
            }
            
        }break;
        case 115:{
            // 删除
            if (self.equal) {
                [self clean];
            } else if (self.text.length) {
                self.text = [self.text substringToIndex:self.text.length - 1 - [self.text isEqualToString:@"0."]];
            }
        }break;
        case 116:{
            // 重置
            [self clean];
        }break;
        case 117:{
            // 等于
            if (self.operaType) {
                if (self.text.length) {
                    // 如果之前点击了运算符, 并且当前输入了数字, 则进行计算
                    [self calcultator];
                    self.equal = YES;
                }
            }
        }break;
        default:
            break;
    }
}

/**
 加减乘除运算
 */
- (NSString *)calcultator {
    double preValue = self.preText.doubleValue;
    double sufValue = self.text.doubleValue;
    double result = 0;
    if (self.operaType == OperaTypeAddition) {
        result = preValue + sufValue;
    } else if (self.operaType == OperaTypeSubtraction) {
        result = preValue - sufValue;
    } else if (self.operaType == OperaTypeMultiplication) {
        result = preValue * sufValue;
    } else if (self.operaType == OperaTypeDivision) {
        result = preValue / sufValue;
    }
    // result就是计算结果, 为了防止结果过大, 使用%g进行科学计数法
    NSString *resultStr = [NSString stringWithFormat:@"%.8g", result];
    if ([resultStr containsString:@"e"]) {
        NSArray *arr = [resultStr componentsSeparatedByString:@"e"];
        if ([arr[1] intValue] < 10 && [arr[1] intValue] > 0) {
            // 有时候系统过早的使用了科学计数, 所以加个判断, 当小于10次幂的时候不使用科学计数法
            resultStr = [NSString stringWithFormat:@"%@", @(result)];
        }
    } else if ([resultStr isEqualToString:@"inf"]) {
        // 报错的时候结果是inf, 比如0做除数的时候
#warning 本demo有一点有待优化: 0不能参与运算, 如果要用0参与运算, 需要加个. eg:要计算一除以零, 点击顺序为 1 ÷ 0 . =
        resultStr = @"";
    }
    [self clean];
    self.text = resultStr;
    return resultStr;
}

- (void)clean {
    self.preText = @"";
    self.text = @"";
    self.operaType = OperaTypeNone;
    self.equal = NO;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"text"];
}

@end
