### Build

1. xcode 打开项目  
2. 配置 app 与 helper 的证书签名
3. build 之后放入 /Application



### 查看签名信息
#### helper
```shell
sudo codesign -d -r- "/Applications/SMJobBlessApp.app/Contents/Library/LaunchServices/com.apple.bsd.SMJobBlessHelper"

designated => identifier "com.apple.bsd.SMJobBlessHelper" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */

<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.apple.bsd.SMJobBlessApp" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */</string>
</array>

# python SMJobBlessUtil.py check /Applications/SMJobBlessApp.app

```

#### app

```shell
sudo codesign -d -r- "/Applications/SMJobBlessApp.app"

designated => identifier "com.apple.bsd.SMJobBlessApp" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */


sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/SMJobBlessApp.app/Contents/Info.plist"
Dict {
    com.apple.bsd.SMJobBlessHelper = identifier "com.apple.bsd.SMJobBlessHelper" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */
}


```

### 清除签名
```shell
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:com.apple.bsd.SMJobBlessHelper \"identifier \\\"com.apple.bsd.SMJobBlessHelper\\\"\"" "/Applications/SMJobBlessApp.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/SMJobBlessApp.app/Contents/Info.plist"

# Dict {
#     com.apple.bsd.SMJobBlessHelper = identifier "com.apple.bsd.SMJobBlessHelper"
# }

chmod  a+x mac_patch_helper 
sudo ./mac_patch_helper "SMJobBlessApp"


sudo codesign -f -s - --all-architectures --deep /Applications/SMJobBlessApp.app/Contents/Library/LaunchServices/com.apple.bsd.SMJobBlessHelper
sudo codesign -f -s - --all-architectures --deep /Applications/SMJobBlessApp.app


sudo launchctl unload /Library/LaunchDaemons/com.apple.bsd.SMJobBlessHelper.plist
sudo rm /Library/LaunchDaemons/com.apple.bsd.SMJobBlessHelper.plist
sudo rm /Library/PrivilegedHelperTools/com.apple.bsd.SMJobBlessHelper
```


### APP 存储相关

| 存储方式                  | 适用范围                  | 获取容器代码 | 存储位置 |
|-------------------------|-------------------------|--------------|---------|
| **SQLite**              | 结构化数据和复杂查询       | `NSString *databasePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"my_database.sqlite"];` | 本地    |
| **Core Data**           | 结构化数据和复杂查询       | `NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];` | 本地    |
| **Keychain**            | 敏感信息                  | `NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: @"com.example.myapp.account", (__bridge id)kSecValueData: [@"my_secure_password" dataUsingEncoding:NSUTF8StringEncoding]};` | 本地    |
| **UserDefaults**        | 用户偏好设置和小量数据      | `NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];` | 本地    |
| **Property List (Plist)** | 结构化配置数据            | `NSString *path = [[NSBundle mainBundle] pathForResource:@"SamplePlist" ofType:@"plist"];` | 本地    |
| **CloudKit**            | 云端数据存储和同步         | `CKContainer *container = [CKContainer defaultContainer];` | iCloud  |
| **iCloud Document Storage** | 文件数据存储和同步     | `NSURL *ubiquityURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];` | iCloud  |


### TODO ??

```
python SMJobBlessUtil.py setreq /Applications/SMJobBlessApp.app SMJobBlessApp/SMJobBlessApp-Info.plist SMJobBlessHelper/SMJobBlessHelper-Info.plist
```


