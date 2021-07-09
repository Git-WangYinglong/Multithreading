//
//  ViewController.m
//  多线程
//
//  Created by change_pan on 2021/7/9.
//

#import "ViewController.h"
#import "SecondViewController.h"

@interface ViewController ()
<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *arr;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"GCD";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStylePlain target:self action:@selector(nextPage)];
    
    _arr = @[@"dispatch_group_First",
             @"dispatch_group_Second",
             @"dispatch_barrier_sync",
             @"dispatch_barrier_async",
             @"dispatch_apply",
             @"dispatch_semaphore_Sync",
             @"dispatch_semaphore_Safe"];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    [self.view addSubview:_tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = _arr[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SEL sel = NSSelectorFromString(_arr[indexPath.row]);
    if ([self respondsToSelector:sel])
    {
        [self performSelector:sel withObject:nil];
    }
}

#pragma mark - Action

- (void)nextPage
{
    SecondViewController *vc = [[SecondViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - dispatch_group

//第一种调度组
- (void)dispatch_group_First
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务1，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务2，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务3，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"监听所有任务结束，当前线程: %@", [NSThread currentThread]);
    });
    
    NSLog(@"当前线程: %@", [NSThread currentThread]);
    
    /*
    2021-07-09 11:14:13.079709+0800 多线程[6172:93405] 当前线程: <NSThread: 0x600002e34b40>{number = 1, name = main}
    2021-07-09 11:14:14.084971+0800 多线程[6172:93474] 任务2，当前线程: <NSThread: 0x600002e70cc0>{number = 3, name = (null)}
    2021-07-09 11:14:15.084969+0800 多线程[6172:93470] 任务1，当前线程: <NSThread: 0x600002e74f00>{number = 7, name = (null)}
    2021-07-09 11:14:15.084974+0800 多线程[6172:93473] 任务3，当前线程: <NSThread: 0x600002e720c0>{number = 6, name = (null)}
    2021-07-09 11:14:15.085289+0800 多线程[6172:93405] 监听所有任务结束，当前线程: <NSThread: 0x600002e34b40>{number = 1, name = main}
     */
}

//第二种调度组
- (void)dispatch_group_Second
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_enter(group);
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务1，当前线程: %@", [NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务2，当前线程: %@", [NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_group_async(group, globalQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务3，当前线程: %@", [NSThread currentThread]);
        dispatch_group_leave(group);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER); //阻塞当前线程
    NSLog(@"监听所有任务结束，当前线程: %@", [NSThread currentThread]);
    
    NSLog(@"当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 11:21:16.154820+0800 多线程[6457:98219] 任务2，当前线程: <NSThread: 0x60000317bb80>{number = 6, name = (null)}
     2021-07-09 11:21:17.153950+0800 多线程[6457:98218] 任务3，当前线程: <NSThread: 0x60000310afc0>{number = 7, name = (null)}
     2021-07-09 11:21:17.153950+0800 多线程[6457:98223] 任务1，当前线程: <NSThread: 0x60000317c940>{number = 3, name = (null)}
     2021-07-09 11:21:17.154267+0800 多线程[6457:98137] 监听所有任务结束，当前线程: <NSThread: 0x600003138040>{number = 1, name = main}
     2021-07-09 11:21:17.154408+0800 多线程[6457:98137] 当前线程: <NSThread: 0x600003138040>{number = 1, name = main}
     */
}

#pragma mark - dispatch_barrier

//栅栏 (同步)
- (void)dispatch_barrier_sync
{
    dispatch_queue_t createQueue = dispatch_queue_create("create", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务1，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务2，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_barrier_sync(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"栅栏，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务3，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务4，当前线程: %@", [NSThread currentThread]);
    });
    
    NSLog(@"当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 13:49:19.513886+0800 多线程[11288:157306] 任务2，当前线程: <NSThread: 0x6000008d5200>{number = 5, name = (null)}
     2021-07-09 13:49:20.513618+0800 多线程[11288:157303] 任务1，当前线程: <NSThread: 0x600000897e80>{number = 7, name = (null)}
     2021-07-09 13:49:21.515135+0800 多线程[11288:157218] 栅栏，当前线程: <NSThread: 0x6000008901c0>{number = 1, name = main}
     2021-07-09 13:49:21.515387+0800 多线程[11288:157218] 当前线程: <NSThread: 0x6000008901c0>{number = 1, name = main}
     2021-07-09 13:49:22.519004+0800 多线程[11288:157306] 任务4，当前线程: <NSThread: 0x6000008d5200>{number = 5, name = (null)}
     2021-07-09 13:49:23.518150+0800 多线程[11288:157303] 任务3，当前线程: <NSThread: 0x600000897e80>{number = 7, name = (null)}
     */
}

//栅栏 (异步)
- (void)dispatch_barrier_async
{
    dispatch_queue_t createQueue = dispatch_queue_create("create", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务1，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务2，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_barrier_async(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"栅栏，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:2.0];
        NSLog(@"任务3，当前线程: %@", [NSThread currentThread]);
    });
    
    dispatch_async(createQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"任务4，当前线程: %@", [NSThread currentThread]);
    });
    
    NSLog(@"当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 13:44:54.063952+0800 多线程[11118:154413] 当前线程: <NSThread: 0x6000033b8980>{number = 1, name = main}
     2021-07-09 13:44:55.068122+0800 多线程[11118:154499] 任务2，当前线程: <NSThread: 0x6000033f4b80>{number = 4, name = (null)}
     2021-07-09 13:44:56.066329+0800 多线程[11118:154495] 任务1，当前线程: <NSThread: 0x600003382140>{number = 6, name = (null)}
     2021-07-09 13:44:57.071754+0800 多线程[11118:154495] 栅栏，当前线程: <NSThread: 0x600003382140>{number = 6, name = (null)}
     2021-07-09 13:44:58.076632+0800 多线程[11118:154496] 任务4，当前线程: <NSThread: 0x6000033f6300>{number = 7, name = (null)}
     2021-07-09 13:44:59.073779+0800 多线程[11118:154495] 任务3，当前线程: <NSThread: 0x600003382140>{number = 6, name = (null)}
     */
}

#pragma mark - dispatch_apply

- (void)dispatch_apply
{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSLog(@"dispatch_apply start，当前线程: %@", [NSThread currentThread]);
    
    dispatch_apply(5, globalQueue, ^(size_t size) {
        if (size == 0) [NSThread sleepForTimeInterval:1.0];
        NSLog(@"dispatch_apply progress:%zd，当前线程: %@", size, [NSThread currentThread]);
    });
    
    NSLog(@"dispatch_apply end，当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 14:09:52.872991+0800 多线程[12163:174042] dispatch_apply start，当前线程: <NSThread: 0x600001d14100>{number = 1, name = main}
     2021-07-09 14:09:52.873290+0800 多线程[12163:174140] dispatch_apply progress:1，当前线程: <NSThread: 0x600001d5ce00>{number = 6, name = (null)}
     2021-07-09 14:09:52.873290+0800 多线程[12163:174137] dispatch_apply progress:2，当前线程: <NSThread: 0x600001d2e000>{number = 4, name = (null)}
     2021-07-09 14:09:52.873431+0800 多线程[12163:174140] dispatch_apply progress:4，当前线程: <NSThread: 0x600001d5ce00>{number = 6, name = (null)}
     2021-07-09 14:09:52.873334+0800 多线程[12163:174042] dispatch_apply progress:3，当前线程: <NSThread: 0x600001d14100>{number = 1, name = main}
     2021-07-09 14:09:53.874661+0800 多线程[12163:174136] dispatch_apply progress:0，当前线程: <NSThread: 0x600001d50940>{number = 7, name = (null)}
     2021-07-09 14:09:53.874915+0800 多线程[12163:174042] dispatch_apply end，当前线程: <NSThread: 0x600001d14100>{number = 1, name = main}
     */
}

#pragma mark - dispatch_semaphore

//信号量 (实现线程同步)
- (void)dispatch_semaphore_Sync
{
    NSLog(@"semaphore start，当前线程: %@", [NSThread currentThread]);
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(globalQueue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"异步任务，当前线程: %@", [NSThread currentThread]);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"semaphore end，当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 14:27:41.794273+0800 多线程[12855:185187] semaphore start，当前线程: <NSThread: 0x60000113c980>{number = 1, name = main}
     2021-07-09 14:27:42.798165+0800 多线程[12855:185262] 异步任务，当前线程: <NSThread: 0x600001121100>{number = 5, name = (null)}
     2021-07-09 14:27:42.798380+0800 多线程[12855:185187] semaphore end，当前线程: <NSThread: 0x60000113c980>{number = 1, name = main}
     */
}

//信号量 (实现线程安全)
static int ticketSurplusCountSafe = 10;
static dispatch_semaphore_t semaphoreLock;

- (void)dispatch_semaphore_Safe
{
    NSLog(@"semaphore start，当前线程: %@", [NSThread currentThread]);
    
    semaphoreLock = dispatch_semaphore_create(1);
    //queue1 代表北京火车票售卖窗口
    dispatch_queue_t queue1 = dispatch_queue_create("net.bujige.testQueue1", DISPATCH_QUEUE_SERIAL);
    //queue2 代表上海火车票售卖窗口
    dispatch_queue_t queue2 = dispatch_queue_create("net.bujige.testQueue2", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue1, ^{
        [self saleTicketSafe];
    });
    dispatch_async(queue2, ^{
        [self saleTicketSafe];
    });
    
    NSLog(@"semaphore end，当前线程: %@", [NSThread currentThread]);
    
    /*
     2021-07-09 14:59:57.807445+0800 多线程[14072:204243] semaphore start，当前线程: <NSThread: 0x600001e2c480>{number = 1, name = main}
     2021-07-09 14:59:57.807728+0800 多线程[14072:204243] semaphore end，当前线程: <NSThread: 0x600001e2c480>{number = 1, name = main}
     2021-07-09 14:59:57.807735+0800 多线程[14072:204443] 剩余票数: 9，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 14:59:58.312727+0800 多线程[14072:204439] 剩余票数: 8，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     2021-07-09 14:59:58.816687+0800 多线程[14072:204443] 剩余票数: 7，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 14:59:59.321180+0800 多线程[14072:204439] 剩余票数: 6，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     2021-07-09 14:59:59.825639+0800 多线程[14072:204443] 剩余票数: 5，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 15:00:00.330225+0800 多线程[14072:204439] 剩余票数: 4，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     2021-07-09 15:00:00.834793+0800 多线程[14072:204443] 剩余票数: 3，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 15:00:01.337048+0800 多线程[14072:204439] 剩余票数: 2，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     2021-07-09 15:00:01.839408+0800 多线程[14072:204443] 剩余票数: 1，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 15:00:02.341844+0800 多线程[14072:204439] 剩余票数: 0，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     2021-07-09 15:00:02.845301+0800 多线程[14072:204443] 所有火车票均已售完，窗口: <NSThread: 0x600001e6a140>{number = 6, name = (null)}
     2021-07-09 15:00:02.845588+0800 多线程[14072:204439] 所有火车票均已售完，窗口: <NSThread: 0x600001e6a500>{number = 7, name = (null)}
     */
}

- (void)saleTicketSafe
{
    while (1) {
        dispatch_semaphore_wait(semaphoreLock, DISPATCH_TIME_FOREVER); //相当于加锁
        if (ticketSurplusCountSafe > 0)
        {
            ticketSurplusCountSafe--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数: %d，窗口: %@", ticketSurplusCountSafe, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.5];
            dispatch_semaphore_signal(semaphoreLock); //相当于解锁
        }
        else
        {
            NSLog(@"%@", [NSString stringWithFormat:@"所有火车票均已售完，窗口: %@", [NSThread currentThread]]);
            dispatch_semaphore_signal(semaphoreLock);
            break;
        }
    }
}

@end
