Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\cr7 1.jpeg' -NewName 'cr7_1.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\cristiano_10.jpg' -NewName 'cristiano_2.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\cristiano_11.jpg' -NewName 'cristiano_3.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\lunin 1.jpeg' -NewName 'lunin_1.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\vini reference.jpeg' -NewName 'vini_1.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\addidas 1.jpeg' -NewName 'adidas_1.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\bbc1.jpeg' -NewName 'bbc_1.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\bbc2.jpeg' -NewName 'bbc_2.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\bbc3.jpeg' -NewName 'bbc_3.jpg' -Force
Rename-Item -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories\bbc4.jpeg' -NewName 'bbc_4.jpg' -Force
Get-ChildItem -LiteralPath 'D:\Dev\stealth_chat\assets\images\stories' | Where-Object { $_.Name -match '^(cr7_1|cristiano_1|cristiano_2|cristiano_3|lunin_1|vini_1|adidas_1|bbc_1|bbc_2|bbc_3|bbc_4)' } | Select-Object Name, Length, LastWriteTime | Sort-Object Name | Format-Table -AutoSize
