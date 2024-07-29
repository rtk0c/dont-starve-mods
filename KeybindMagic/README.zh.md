# KeybindMagic

KeybindMagic是一个单文件、可vendor的用于添加快捷键的饥荒模组库。快捷键可以在在 选项 > 控制 页面里重新绑定，并且 模组 > \[模组名\] > 配置模组 页面里的，对应快捷键的选项的复选框会被自动替换成按下按键就能绑定的输入框。

KeybindMagic设计之初就考虑到了饥荒联机版模组管理依赖的不便，因此就算被多个模组重复引用，重复执行各自的副本也能正常工作。

## 技术限制
由于模组的配置项（`configuration_options`）只能从一个有限的列表中取值，KeybindMagic的快捷键只支持绑定单独一个按键。ctrl、shift、alt等都在技术上无法支持。

## 快速开始
把`keybind_magic.lua`复制到你的模组里。关于如何添加快捷键，请参考`modinfo.lua`。关于如何在代码中读取、使用快捷键所绑定的按键，请参考`modmain.lua`。
