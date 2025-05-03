@echo off
color F0
mode con cols=58 lines=30
title=m4a to mp3 v1.0 :By:Bilibili@United-States__
if not exist D:\ffmpeg (
cd /d %~dp0
xcopy ffmpeg D:\ /E/Y
setx path "D:\ffmpeg\bin"
echo 初始化成功！)
if exist D:\ffmpeg (echo 无需重复初始化！)
pause