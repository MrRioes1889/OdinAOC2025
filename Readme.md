<h1>OdinAOC2025</h1>
<h2>Contents</h2>
A late to the party implementation of solutions to the ["Advent of Code" puzzles for the year 2025](https://adventofcode.com/2025).<br>
The main motivation is to get used to the Odin programming language and have some fun.
<h2>How to build</h2>
<h3>General</h3>
All subdirectories labeled like "day_*" should be buildable using the Odin runtime found at [https://odin-lang.org/](https://odin-lang.org/) using the command:
```
odin build . 
```
with flags added for platform and optimizations respectively.
<h3>Windows - x64</h3>
For compiling on Windows for x64 architecture bat files are provided. The Odin runtime needs to be registerd in the system's path.
- Running 
```
build.bat 
```
without arguments builds for release. 
- Running 
```
build.bat -d 
```
builds with debug symbols and minimal optimizations.
<h2>Usage</h2>
The input.txt files in the subdirectories need to be replaced with respective input text provided from the puzzles. 
The executable expect input.txt in the working directory, or the path can be provided as such: 
```
day_x.exe path/to/input.txt
```
