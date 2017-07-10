# JXWebFile V1.0
This rookie's Project is used to download files and review them with one line of code (sadly,now more...)!
Resume broken downloads supported！
Resume broken downloads after KILL the app supported！
## TODO
1.Upload Files

## Installation

[CocoaPods](http://cocoapods.org) is the recommended way of installation, as this avoids including any binary files into your project.

### CocoaPods (recommended)

JXWebFile is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your [Podfile](http://cocoapods.org/#get_started) and run `pod install`.

```ruby
pod "JXWebFile"
```

### Manually

Clone(`git clone https://github.com/zhujiaxiang/JXWebFile.git`) or  Download [SJFileCache](https://github.com/zhujiaxiang/JXWebFile/archive/master.zip), then drag `JXWebFile` subdirectory to your Project.


## Usage

In your Project,add `#import <JXWebFile/JXWebFile.h>` statement and delegate. As shown below:

```Objc
@interface ViewController () <UITableViewDelegate, UITableViewDataSource, JXWebFileDemoCellDelegate>

- (nullable JXWebFileDownloadOperation *)downloadFileWithURL:(nonnull NSURL *)fileURL progress:(nullable JXWebFileDownloaderProgressBlock)progressBlock completed:(nullable JXWebFileDownloaderCompletedBlock)completedBlock
```

## Requirements

* Deployment Target iOS9.0+
* ARC
* AutoLayout


## Contribute

Please post any issues and ideas in the GitHub issue tracker and feel free to submit pull request with fixes and improvements. Keep in mind; a good pull request is small, well explained and should benifit most of the users.


## License

JXWebFile is available under the MIT license. See the LICENSE file for more info.
