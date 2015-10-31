# cproto_completion
A c++ vim plugin that complete your header or implementation's prototype.
In Visual Studio, there is a cool feature that will automatically create a function prototype in your implementation file when you create your prototype in your header file. This feature save me a lot of time, and there isn't any plugins out there, from what I know, for vim that do this. This little plugin does the job. At the moment, it requires python for vim.

At the moment, this plugin only works on Linux. I have not try it on Windows or Mac.
##Installation##
Install using `pathogen` is recommended.
```
cd ~/.vim/bundle &&
git clone https://github.com/pham93/cproto_completion
```
