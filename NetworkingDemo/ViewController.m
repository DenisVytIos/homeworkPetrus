//
//  ViewController.m
//  NetworkingDemo
//
//  Created by Denis on 29.12.2018.
//  Copyright © 2018 Denis Vitrishko. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDataDelegate,NSURLSessionDelegate,NSURLSessionTaskDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;



@property (strong, nonatomic)NSURLSessionDataTask *bigFileTask;
@property (strong, nonatomic)NSMutableData *bigFileData;
@property(nonatomic) double expectedBigFileLenght;

@end

@implementation ViewController

-(void)loadImageAsync{
    
    NSString *urlString = @"https://www.5.ua/media/pictures/original/39937.jpg";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        __block UIImage *newImage = [UIImage imageWithData:data];
        //переходим в главный поток, что-бы изменить пользовательский интерфейс
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = newImage;
            [self.loadingIndicator stopAnimating];
        });
        NSLog(@"FinishedFoto");
    }];
    [dataTask resume];
    
}
-(void)loadBigFileWhithCencelButton{
//    https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.6.0-amd64-netinst.iso
//    https://upload.wikimedia.org/wikipedia/commons/9/9e/%D0%91%D0%BE%D0%BB%D1%8C%D1%88%D0%B0%D1%8F_%D0%9D%D0%B5%D0%B2%D0%BA%D0%B0%2C_%D0%B2%D0%B8%D0%B4_%D1%81_%D0%93%D1%80%D0%B5%D0%BD%D0%B0%D0%B4%D0%B5%D1%80%D1%81%D0%BA%D0%BE%D0%B3%D0%BE_%D0%BC%D0%BE%D1%81%D1%82%D0%B0.jpg
    NSString *urlString = @"https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.6.0-amd64-netinst.iso";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    self.bigFileTask = [defaultSession dataTaskWithURL:url];

    [self.bigFileTask resume];
    
}
//https://fex.net/197226555938?fileId=1080556375
//https://fs3.fex.net/get/197226555938/1080556375/11d8d6cc/samplejson.json

-(void) jsonResponse{
    NSString *urlString = @"https://fs3.fex.net/get/197226555938/1080556375/11d8d6cc/samplejson.json";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *jsonTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *serializationError = nil;
            //преобразуем данные с сервера в Dictionary
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments| NSJSONReadingMutableLeaves ) error:&serializationError];
            if (!serializationError) {
               //проверяем вдруг мы хотим перевести текстовый файл в json
                NSLog(@"%@",jsonDictionary[@"colors"]);
            }
        }else{
            NSLog(@"URL is incorrect!");
        }
    }];
    
    [jsonTask resume];
    
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.loadingIndicator startAnimating];
    [self loadImageAsync];
    [self loadBigFileWhithCencelButton];
    //[self jsonResponse];
}

- (IBAction)cancelLoadingAction:(UIButton *)sender {
    if (self.bigFileTask.state == NSURLSessionTaskStateRunning) {
        [self.bigFileTask suspend];
    }else{
        [self.bigFileTask resume];
    }
    //[self.bigFileTask cancel];
}
#pragma mark - Delegate Download

//вызывается когда мы получили наш ответ
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    
    if(dataTask == self.bigFileTask) {
        
        NSLog(@"Response received.Starting download");
        self.expectedBigFileLenght = [response expectedContentLength];//размер файла
    
        //создадим пустой блок с данными
        self.bigFileData = [NSMutableData data];
        
    }
}
//в этом методе можна по посчитать сколько данных мы уже получили
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    if (dataTask == self.bigFileTask) {
        
        [self.bigFileData  appendData:data ];
       // NSLog(@"Received: %lu", (unsigned long)self.bigFileData.length);
        NSLog(@"Received: %.2f", ((double)self.bigFileData.length/self.expectedBigFileLenght) * 100.0);
    }
    

}
@end
