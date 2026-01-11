# OdinAOC2025

## Contents
#### A late to the party implementation of solutions to the ["Advent of Code" puzzles of 2025](https://adventofcode.com/2025).<br>The main motivation is to get used to the Odin programming language and have some fun.

## How to build
### General
All subdirectories labeled like "day_*" should be buildable using the Odin runtime found at [https://odin-lang.org/](https://odin-lang.org/) using the command:
```
odin build . 
```
with flags added for platform and optimizations respectively.
### Windows - x64
For compiling on Windows for x64 architecture bat files are provided. The Odin runtime needs to be registerd in the system's path.
- Build for release:
```
build.bat 
```
- Build with debug symbols and minimal optimizations:
```
build.bat -d
```

## Usage
Input gets generated for the puzzles for each AOC account individually. 
The input.txt files in the subdirectories need to be replaced with the respective input text.
The executable expect input.txt in the working directory, or the path can be provided as such: 
```
day_x.exe path/to/input.txt
```
