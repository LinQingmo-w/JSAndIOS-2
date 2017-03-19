//
//  ViewController.m
//  JSAndIOS
//
//  Created by 凡建波 on 16/6/24.
//  Copyright © 2016年 QF. All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface ViewController ()<UIWebViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic,strong)UIWebView * webView;
@property (nonatomic,strong)UIImagePickerController * imgPicker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createWebView];
}
- (void)createWebView{

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
//    self.webView.scalesPageToFit = YES;
//    webView的这个属性就是设置html数据的样式大小适应webView的大小
    
//    【说明】UIWebView是苹果官方的UIKit框架中提供的一个加载HTML数据控件，该控件是基于浏览器内核开发的，因此UIWebView具备浏览器的所有功能
    
    NSString * urlStr1 = [[NSBundle mainBundle] pathForResource:@"myH5" ofType:@"html"];
    
    NSString * urlStr2 = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"html"];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr1]]];
    
    
}

//webView代理方法
- (void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"开始加载HTML数据！");

}


- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    NSLog(@"HTML数据加载完成！");
    /***OC语言调用js代码**/
    //OC调用js要在HTML文档全部加载完毕以后调用
    //1、创建交互上下文，所有的交互都要通过上下文对象进行
    JSContext * context = [[JSContext alloc] init];
    //2、执行js语句,在OC中执行js语句要借助于上下文调用上下文的相关方法
    JSValue * jval = [context evaluateScript:@"1 + 3"];
//    evaluateScript方法用于执行js语句，后面的参数传的就是js语句对应的字符串
//    JSValue是js中的变量声明关键字var在oc中的映射
    NSLog(@"%@",jval);
//    也可以将js中的变量转化为oc中的变量
    int a = [jval toInt32];
    
    //声明一个js变量
    [context evaluateScript:@"var p = ['123',1.23,true]"];
//    从OC中获取js变量
    JSValue * jArr = context[@"p"];
    NSLog(@"从JS中获取了一个数组：%@",jArr);
    NSLog(@"将以上获取的js数组转为OC数组：%@",[jArr toArray]);
    
    //声明一个函数
    [context evaluateScript:@"function func1(){return '你好！'}"];
//    [context evaluateScript:@"alert('警示框！')"];
    //执行一个js函数
    JSValue * jStr = [context evaluateScript:@"func1()"];
    NSLog(@"%@",jStr);
    //转化成OC字符串
    NSString * str = [jStr toString];
    
    //通过上下文给js加一个变量,context[@"func2"]相当于在js写var func2 = function(){}
    context[@"func2"] = ^(){
        NSLog(@"你好！我是js里面的一个函数的函数体！");
    };
    
//    调用该函数
    [context evaluateScript:@"func2()"];
    /*【总结】
     1、在oc中执行js代码要借助于上下文JSContext对象
     2、在OC中运行js语句要用context对象调evaluateScript：方法，将js代码传入该对象，具体的js代码处理交给context对象
     3、在oc中使用或声明js变量格式context[@"变量名"]
     4、js中的var映射到oc中是对象JSValue
     */
    
    
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, 30, 200, 30)];
    button.tag = 11;
    [button setTitle:@"点击改变webView界面" forState:UIControlStateNormal];
    
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor grayColor];
    
    [button addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:button];
}
- (void)clicked:(UIButton *)button{
    
//    创建上下文，关联webView
    JSContext * context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    [context evaluateScript:@"alert('你好！我是webView的警示框！')"];
    
    //创建一句js代码
    NSString * jsStr1 = @"var h1 = document.getElementsByTagName('h1')[0];h1.innerHTML = '沁园春.雪<br>毛泽东'";
    [context evaluateScript:jsStr1];
    
//    写一句js语句，获取输入框的内容
    NSString * jsStr2 = @"var text = document.getElementById('txt');var s = text.value";
    [context evaluateScript:jsStr2];
    JSValue * jval = context[@"s"];
    NSLog(@"%@",jval);//empty
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, 100, 200, 60)];
    label.backgroundColor = [UIColor yellowColor];
    label.textColor = [UIColor redColor];
    [self.view addSubview:label];
    label.text = [jval toString];
    
    
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
    NSLog(@"HTML数据加载失败！");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{

    NSLog(@"webView页面元素发出请求！");
    
//    js调用OC代码要在此处调
    NSLog(@"%@",request.URL.absoluteString);
    //1、拿到js与OC通话的规则
    NSString * urlStr = request.URL.absoluteString;
//    msg://func
    //2、提取出规则中的方法名
    if ([urlStr rangeOfString:@"msg://"].location != NSNotFound) {
        //在对话的时候要首先判断当前请求是否为我们制定的那个规则
        
        NSString * fName = [urlStr substringFromIndex:6];
        //    NSLog(@"%@",fName);
        //3、通过一个方法名生成选择器
        SEL sel = NSSelectorFromString(fName);
        
        //    4、调用选择器
        [self performSelector:sel];
    }
    
  
    
    return YES;
}
- (void)func{
    NSLog(@"我是被js调用的OC的方法！");
    UIButton * btn = (id)[self.view viewWithTag:11];
    
    btn.transform = CGAffineTransformMakeRotation(100);
}

//js代码调用OC，要依赖于制定的那个通信规则
//OC代码调用JS，要依赖于上下文



- (void)openCamera{
    

    _imgPicker = [[UIImagePickerController alloc] init];
    _imgPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imgPicker.allowsEditing = YES;
    _imgPicker.delegate = self;
    
    [self presentViewController:_imgPicker animated:YES completion:nil];
    

}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [_imgPicker dismissViewControllerAnimated:YES completion:nil];
    UIImage * img = info[UIImagePickerControllerEditedImage];
    
    NSMutableData * data = [NSMutableData data];
    NSKeyedArchiver * kA = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [kA encodeObject:img forKey:@"img"];
    [kA finishEncoding];
    NSString * path = [NSString stringWithFormat:@"%@/Library/Caches/testImg.jpeg",NSHomeDirectory()];
    NSLog(@"%@",path);
    

    
    [data writeToFile:path atomically:YES];
    
    
     JSContext * context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    NSString * jsStr = @"var photo = document.getElementsById('photo'); photo.src=%@";
    NSString * showPhotoJsStr = [NSString stringWithFormat:@"%@%@",jsStr,path];
    
    
    [context evaluateScript:showPhotoJsStr];
    
    
    
}






@end
