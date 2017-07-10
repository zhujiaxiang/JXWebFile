//
//  ViewController.m
//  JXWebFileDemo
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import "ViewController.h"
#import "JXWebFile.h"
#import <Masonry/Masonry.h>

typedef NS_ENUM(NSInteger, JXCellStatus) {
    JXCellStatusUnStarted = 0, /* The task is currently being serviced by the session */
    JXCellStatusRunning = 1,
    JXCellStatusCanceled = 2,  /* The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message. */
    JXCellStatusCompleted = 3, /* The task has completed and the session will receive no more delegate notifications */
};

@class JXWebFileDemoCell;

@protocol JXWebFileDemoCellDelegate <NSObject>

@optional

- (void)JX_JXWebFileDemoCellDidClickCancelButton:(nonnull JXWebFileDemoCell *)cell;

@end

@interface JXWebFileDemoCellViewModel : NSObject

@property(nullable, nonatomic, copy) NSString *titleText;
@property(nullable, nonatomic, copy) NSString *detailText;
@property(nonatomic, assign) JXCellStatus status;

@end

@implementation JXWebFileDemoCellViewModel

@end

@interface JXWebFileDemoCell : UITableViewCell

@property(nullable, nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) JXWebFileDemoCellViewModel *viewModel;
@property(nullable, nonatomic, weak) id<JXWebFileDemoCellDelegate> delegate;

- (void)bindDataWithViewModel:(nonnull JXWebFileDemoCellViewModel *)viewModel;

@end

@implementation JXWebFileDemoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        
        self.backgroundColor = [UIColor whiteColor];
        self.textLabel.textColor = [UIColor darkTextColor];
        self.textLabel.font = [UIFont fontWithName:@"Heiti SC" size:17];
        
        self.cancelButton = ({
            UIButton *view = [[UIButton alloc] init];
            
            [self.contentView addSubview:view];
            view.titleLabel.font = [UIFont fontWithName:@"Heiti SC" size:15];
            [view setTintColor:[UIColor darkGrayColor]];
            [view setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
            view.layer.cornerRadius = 3.0f;
            view.layer.masksToBounds = YES;
            [view setTitle:@"取消" forState:UIControlStateNormal];
            view.hidden = YES;
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.mas_equalTo(view.superview.mas_centerY);
                make.right.mas_equalTo(view.superview.mas_right).offset(-15.0f);
            }];
            [view addTarget:self action:@selector(onCancelButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            view;
        });
    }
    return self;
}

#pragma mark - Actions

- (void)onCancelButtonTouchUpInside:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(JX_JXWebFileDemoCellDidClickCancelButton:)]) {
        [self.delegate JX_JXWebFileDemoCellDidClickCancelButton:self];
    }
}

#pragma mark - Public APIs

- (void)bindDataWithViewModel:(JXWebFileDemoCellViewModel *)viewModel
{
    _viewModel = viewModel;
    self.textLabel.text = viewModel.titleText;
    self.detailTextLabel.text = viewModel.detailText;
    
    switch (viewModel.status) {
        case JXCellStatusUnStarted: {
            self.cancelButton.hidden = YES;
            break;
        }
        case JXCellStatusRunning: {
            self.cancelButton.hidden = NO;
            break;
        }
        case JXCellStatusCanceled: {
            self.cancelButton.hidden = YES;
            break;
        }
        case JXCellStatusCompleted: {
            self.cancelButton.hidden = YES;
            
            break;
        }
    }
    [self reloadInputViews];
}

@end

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, JXWebFileDemoCellDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nullable, nonatomic, strong) NSMutableArray *items;
@property(strong, nonatomic, nullable) NSMutableDictionary<NSURL *, JXWebFileDownloadOperation *> *URLOperations;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _URLOperations = [NSMutableDictionary new];
    [JXWebFileDownloader sharedDownloader];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(onClickRightNavBarButton:)];
    
    self.tableView = ({
        
        UITableView *view = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        view.backgroundColor = [UIColor clearColor];
        [self.view addSubview:view];
        
        view.delegate = self;
        view.dataSource = self;
        view;
    });
    
    self.items = ({
        
        NSMutableArray *array = [[NSMutableArray alloc] init];
        {
            NSDictionary *item = @{ @"title" : @"测试文件#1.mp4",
                                    @"downloadUrl" : @"http://baobab.wdjcdn.com/1456117847747a_x264.mp4",
                                    @"size" : @"144.8 MB" };
            [array addObject:item];
        }
        {
            NSDictionary *item = @{ @"title" : @"测试文件#2.mp4",
                                    @"downloadUrl" : @"http://baobab.wdjcdn.com/14525705791193.mp4",
                                    @"size" : @"37.4 MB" };
            [array addObject:item];
        }
        {
            NSDictionary *item = @{ @"title" : @"测试文件#3.mp4",
                                    @"downloadUrl" : @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4",
                                    @"size" : @"46.7 MB" };
            [array addObject:item];
        }
        {
            NSDictionary *item = @{ @"title" : @"测试文件#4.zip",
                                    @"downloadUrl" : @"http://www.neegle.net/kunlunMedia/upload/201708/a494d97e-7967-4e9a-b445-05c9152a4d78.zip",
                                    @"size" : @"6.1 MB" };
            [array addObject:item];
        }
        array;
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)JX_JXWebFileDemoCellDidClickCancelButton:(nonnull JXWebFileDemoCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *item = [self.items objectAtIndex:indexPath.section];
    
    NSString *urlStr = [item valueForKey:@"downloadUrl"];
    
    [[JXWebFileDownloader sharedDownloader] cancelDownloadWithURL:[[NSURL alloc] initWithString:urlStr]];
}

- (void)onClickRightNavBarButton:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"设置"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"清除所有缓存"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction *action) {
                                                            
                                                            [[JXFileCache sharedFileCache] clearAllDiskCache];
                                                        }];
    
    [alert addAction:cancelAction];
    [alert addAction:clearAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.items objectAtIndex:indexPath.section];
    
    NSString *title = [item valueForKey:@"title"];
    NSString *urlStr = [item valueForKey:@"downloadUrl"];
    
    NSString *identifier = NSStringFromClass([JXWebFileDemoCell class]);
    JXWebFileDemoCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[JXWebFileDemoCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    JXWebFileDownloadOperation *operation = [self findOperationForURL:[NSURL URLWithString:urlStr]];
    JXWebFileDemoCellViewModel *vm = [[JXWebFileDemoCellViewModel alloc] init];
    
    vm.titleText = title;
    
    
    if (!operation && cell.viewModel.status == JXCellStatusCanceled) {
        vm.detailText = @"取消下载";
        [cell bindDataWithViewModel:vm];
    }else if (!operation  && cell.viewModel.status == JXCellStatusCompleted){
        vm.detailText = [NSString stringWithFormat:@"%@ / %@", @"已下载", [item valueForKey:@"size"]];
        vm.status = JXCellStatusCompleted;
        [cell bindDataWithViewModel:vm];
    }else if (!operation) {
        vm.detailText = [NSString stringWithFormat:@"%@ / %@", @"未下载", [item valueForKey:@"size"]];
        vm.status = JXCellStatusUnStarted;
        [cell bindDataWithViewModel:vm];
    } else {
        vm.detailText = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:operation.bytesWritten countStyle:NSByteCountFormatterCountStyleDecimal], [NSByteCountFormatter stringFromByteCount:operation.totalBytes countStyle:NSByteCountFormatterCountStyleDecimal]];
        vm.status = JXCellStatusRunning;
        [cell bindDataWithViewModel:vm];
    }
    
    
    cell.delegate = self;
    return cell;
}

- (JXWebFileDownloadOperation *)findOperationForURL:(NSURL *)URL
{
    return self.URLOperations[URL];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self.items objectAtIndex:indexPath.section];
    
    NSString *urlStr = [item valueForKey:@"downloadUrl"];
    
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    JXWebFileDemoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    JXWebFileDownloadOperation *operation = [[JXWebFileDownloader sharedDownloader] downloadFileWithURL:url
                                                                                               progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {
                                                                                                   
                                                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                       NSString *str = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:receivedSize countStyle:NSByteCountFormatterCountStyleDecimal], [NSByteCountFormatter stringFromByteCount:expectedSize countStyle:NSByteCountFormatterCountStyleDecimal]];
                                                                                                       JXWebFileDemoCellViewModel *vm = cell.viewModel;
                                                                                                       vm.detailText = str;
                                                                                                       vm.status = JXCellStatusRunning;
                                                                                                       [cell bindDataWithViewModel:vm];
                                                                                                       
                                                                                                       [tableView reloadData];
                                                                                                   });
                                                                                                   
                                                                                               }
                                                                                              completed:^(NSURL *_Nullable localFileURL, NSError *_Nullable error, BOOL finished) {
                                                                                                  if (finished == true) {
                                                                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                          JXWebFileDemoCellViewModel *vm = cell.viewModel;
                                                                                                          vm.detailText = @"已下载";
                                                                                                          vm.status = JXCellStatusCompleted;
                                                                                                          [cell bindDataWithViewModel:vm];
                                                                                                          [self.URLOperations removeObjectForKey:url];
                                                                                                          [tableView reloadData];
                                                                                                      });
                                                                                                  } else if (error.code == -999) {
                                                                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                          JXWebFileDemoCellViewModel *vm = cell.viewModel;
                                                                                                          vm.detailText = @"取消下载";
                                                                                                          vm.status = JXCellStatusCanceled;
                                                                                                          [cell bindDataWithViewModel:vm];
                                                                                                          [self.URLOperations removeObjectForKey:url];
                                                                                                          [tableView reloadData];
                                                                                                      });
                                                                                                  }
                                                                                              }];
    if (operation) {
        self.URLOperations[url] = operation;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 350;
}

@end

