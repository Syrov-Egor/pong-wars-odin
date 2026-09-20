# Pong wars in Odin + raylib
![Demo video](assets/pong_wars.gif)

# Idea
The original idea belongs to [Koen van Gilst](https://github.com/vnglst/pong-wars).The main twist of this version is simulation speed control (from 0x - total stop up to 5x of default speed).

# Installation
To compile it, you'll need the latest [Odin compiler](https://odin-lang.org/docs/install/) installed with [git-lfs](https://git-lfs.com/) enabled to include vendor packages. Also, don't forget to add the Odin compiler executable to your PATH.

Then, `git clone` this repo, and:
```Bash
cd pong-wars-odin
```
If you are using [go-task](https://taskfile.dev/):
```Bash
task launch
```
or just
```Bash
odin build . -out:bin/pong
```

## License
The code is provided under the MIT license.

Roboto Mono font was designed by Christian Robertson and licensed under the [SIL Open Font License, Version 1.1](https://openfontlicense.org/open-font-license-official-text/).