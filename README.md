## 问题描述
越来越多的智能设备使用到了Firefly的开发板（http://dev.t-firefly.com/forum.php），有时候android应用开发必须要获取root权限（如重启设备、静默升级app），一般厂家都会提供获取root权限的方式，但是总有人不知道如何获取root。

## 解决办法
Firefly论坛有一篇关于获取root权限的帖子（[传送门](http://dev.t-firefly.com/thread-300-1-1.html)），前提是设备要能连接到电脑，通过adb来操作。

1.设备连接到电脑，通过ADB调试；

2.下载附件root.tar和quick_root.tar，解压缩quick_root.tar(终端运行tar xf quick_root.tar)--->最好在电脑上解压

3.打开终端运行如下命令
```java
adb remount
adb push root.tar system/usr/root.tar
adb push quick_root.sh system/usr/
adb shell 
```

接着运行

```java
root@rk3288:/ # cd system/usr/                                                 
root@rk3288:/system/usr # chmod 777 quick_root.sh                              
root@rk3288:/system/usr # ./quick_root.sh 
```
会自动安装和配置相关文件，配置完成后会自动重启，重启后就已经获得ROOT权限了。

## 特殊情况

特殊情况总是有的，比如我接触到的一批设备是没有调试接口的，也就无法连接电脑（你可能会说可以用无线adb方式来连接，遗憾的是wifi功能已经被禁了，只能用有线）进行ADB调试；你可能想到了可以在android设备上面运行adb命令嘛，是的，可以的，google就提供了这么一个工具，[下载地址传送门](https://jackpal.github.io/Android-Terminal-Emulator/downloads/Term.apk)  ，该工具用法就跟电脑中使用adb一样。命令同上。

## 终极解决办法
有没有更简单的方式，比如一键获取root权限，有的，下面就是解决方案

> 一键获取Root权限工具RootUtils-->方式一： https://fir.im/7pw9

用法：点击**“获取Root权限”**，稍等片刻，设备重启完成即可，真正的一键获取

![这里写图片描述](https://img-blog.csdn.net/2018082914451033?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxMTM3NzIyNjk3/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

下面来说说如何实现，博主真好，源码都公布了，还不点个赞（不想了解的就跳过了哈）

## 实现方法
只需要一行代码就搞定，不信你看

```java
ShellUtils.execCommand("remount \n push file:///android_asset/root.tar system/usr/root.tar \npush file:///android_asset/quick_root.sh system/usr/\ncd system/usr/\nchmod 777 quick_root.sh\n./quick_root.sh ", false);
```

>你逗我呢，ShellUtils又不是系统API肯定不止一行代码啦（杠精同志的话）

我们来看看这个方法实现了什么功能，其实就是执行了一条shell命令（每条命令以‘\n’结尾），即将assets文件夹下的root.tar和quick_root.sh复制到system/usr文件夹中，然后执行quick_root.sh脚本自动获取root。

### 第一步

所以第一步就是将root.tar和quick_root.sh放到assets文件夹下面（你放哪里都无所谓，只要app能读取到就行）

### 第二步

来看看ShellUtils是怎么实现的（此类出自网络，感谢作者）

```java
package com.hdl.rootutils;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;

/**
 * Shell工具类
 * Created by HDL on 2018/8/6.
 */

public class ShellUtils {
    public static final String COMMAND_SU = "su";
    public static final String COMMAND_SH = "sh";
    public static final String COMMAND_EXIT = "exit\n";
    public static final String COMMAND_LINE_END = "\n";

    private ShellUtils() {
        throw new AssertionError();
    }

    /**
     * 查看是否有了root权限
     *
     * @return
     */
    public static boolean checkRootPermission() {
        return execCommand("echo root", true, false).result == 0;
    }


    /**
     * 执行shell命令，默认返回结果
     *
     * @param command command
     * @return
     * @see ShellUtils#execCommand(String[], boolean, boolean)
     */
    public static CommandResult execCommand(String command, boolean isRoot) {
        return execCommand(new String[]{command}, isRoot, true);
    }


    /**
     * 执行shell命令，默认返回结果
     *
     * @param commands command list
     * @return
     * @see ShellUtils#execCommand(String[], boolean, boolean)
     */

    public static CommandResult execCommand(List<String> commands, boolean isRoot) {
        return execCommand(commands == null ? null : commands.toArray(new String[]{}), isRoot, true);
    }


    /**
     * 执行shell命令，默认返回结果
     *
     * @param commands command array
     * @return
     * @see ShellUtils#execCommand(String[], boolean, boolean)
     */

    public static CommandResult execCommand(String[] commands, boolean isRoot) {
        return execCommand(commands, isRoot, true);
    }


    /**
     * execute shell command
     *
     * @param command         command
     * @param isNeedResultMsg whether need result msg
     * @return
     * @see ShellUtils#execCommand(String[], boolean, boolean)
     */
    public static CommandResult execCommand(String command, boolean isRoot, boolean isNeedResultMsg) {
        return execCommand(new String[]{command}, isRoot, isNeedResultMsg);
    }


    /**
     * execute shell commands
     *
     * @param commands command list
     * @return
     * @see ShellUtils#execCommand(String[], boolean, boolean)
     */
    public static CommandResult execCommand(List<String> commands, boolean isRoot, boolean isNeedResultMsg) {

        return execCommand(commands == null ? null : commands.toArray(new String[]{}), isRoot, isNeedResultMsg);
    }


    /**
     * execute shell commands
     */
    public static CommandResult execCommand(String[] commands, boolean isRoot, boolean isNeedResultMsg) {
        int result = -1;
        if (commands == null || commands.length == 0) {
            return new CommandResult(result, null, null);
        }
        Process process = null;
        BufferedReader successResult = null;
        BufferedReader errorResult = null;
        StringBuilder successMsg = null;
        StringBuilder errorMsg = null;
        DataOutputStream os = null;
        try {
            process = Runtime.getRuntime().exec(isRoot ? COMMAND_SU : COMMAND_SH);
            os = new DataOutputStream(process.getOutputStream());
            for (String command : commands) {
                if (command == null) {
                    continue;
                }
                // donnot use os.writeBytes(commmand), avoid chinese charset
                // error
                os.write(command.getBytes());
                os.writeBytes(COMMAND_LINE_END);
                os.flush();
            }
            os.writeBytes(COMMAND_EXIT);
            os.flush();
            result = process.waitFor();
            // get command result
            if (isNeedResultMsg) {
                successMsg = new StringBuilder();
                errorMsg = new StringBuilder();
                successResult = new BufferedReader(new InputStreamReader(process.getInputStream()));
                errorResult = new BufferedReader(new InputStreamReader(process.getErrorStream()));
                String s;
                while ((s = successResult.readLine()) != null) {
                    successMsg.append(s);
                }
                while ((s = errorResult.readLine()) != null) {
                    errorMsg.append(s);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (os != null) {
                    os.close();
                }
                if (successResult != null) {
                    successResult.close();
                }
                if (errorResult != null) {
                    errorResult.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            if (process != null) {
                process.destroy();
            }
        }
        return new CommandResult(result, successMsg == null ? null : successMsg.toString(), errorMsg == null ? null : errorMsg.toString());
    }

    public static class CommandResult {
        /**
         * 运行结果
         **/
        public int result;
        /**
         * 运行成功结果
         **/
        public String successMsg;
        /**
         * 运行失败结果
         **/
        public String errorMsg;

        public CommandResult(int result) {
            this.result = result;
        }

        public CommandResult(int result, String successMsg, String errorMsg) {
            this.result = result;
            this.successMsg = successMsg;
            this.errorMsg = errorMsg;
        }
    }
}

```

下面是GIthub的地址，如果你觉得帮助到你了，来个star吧，更欢迎你fork新增更多实用功能。
