### About

SMJobBless展示了如何安全地安装一个执行特权操作的辅助工具，以及如何将该工具与调用它的应用程序关联起来。

源于官方demo(https://developer.apple.com/library/archive/samplecode/SMJobBless/Introduction/Intro.html) , 做了一些升级:  

- 升级了 xcode 版本
- helper 中添加了 sec 相关函数校验

helper install 成功, xpc 连接成功后,  主程序窗口会看到 “Successfully connected to HelperTool” 字样提示;

喜欢逆向的同学, 可以拿来 resign / 练手;


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


### TODO ??

```
python SMJobBlessUtil.py setreq /Applications/SMJobBlessApp.app SMJobBlessApp/SMJobBlessApp-Info.plist SMJobBlessHelper/SMJobBlessHelper-Info.plist
```


