# [namesmt/linux-stuff](https://github.com/NamesMT/linux-stuff) - [Dockerhub link](https://hub.docker.com/r/namesmt/linux-stuff)
![Docker Pulls](https://img.shields.io/docker/pulls/namesmt/linux-stuff)
![Docker Image Size (alpine-node)](https://img.shields.io/docker/image-size/namesmt/linux-stuff/alpine-node?label=image%20size%3Anode)
![Docker Image Size (alpine-node-aws-dev)](https://img.shields.io/docker/image-size/namesmt/linux-stuff/alpine-node-aws-dev?label=image%20size%3Anode-aws-dev)

### Features:

- Latest Node LTS & pnpm (**node** tag)
  - [@antfu/ni](https://github.com/antfu/ni)
- Self-built latest aws-cli v2 (**aws** tag)
- git + Oh My Zsh! (**dev** tag)
  - Theme: [spaceship](https://spaceship-prompt.sh/)
    - SPACESHIP_USER_SHOW=false
    - SPACESHIP_DIR_TRUNC_REPO=false
  - Plugins:
    - command-not-found
    - git
    - history-substring-search
    - z
    - https://github.com/zsh-users/zsh-autosuggestions
    - https://github.com/zsh-users/zsh-completions
    - https://github.com/zsh-users/zsh-syntax-highlighting
- These common packages are installed for all:
  - `zip` `unzip` `jq` `sudo` `less` `zsh` `curl` `wget`
  - *alpine-only:* `gcompat` `libstdc++`

---

### Use:

*(new versions are auto-built on new pnpm releases for now, their release cycle is good anchor point for new images, as well as I like to micro-optimize my CI build time by using the exact pnpm version :D)*

Available on Docker registry:
```sh
docker run -it --rm namesmt/linux-stuff:alpine-node-dev

# For CIs, you should pin the version: 
docker run -it --rm namesmt/linux-stuff:node-dev_pnpm8.10.5
```

### Available Scripts:

#### Alpine:

##### `alpine-node-dev` dev environment setup:

*(Tips: Follow [Yuka](https://github.com/yuk7/AlpineWSL)'s instruction to install Alpine WSL2)*

Run `alpine-node-dev` script: *([`fnm`](https://github.com/Schniz/fnm) included to manage node version)*
```sh
wget https://raw.githubusercontent.com/NamesMT/linux-stuff/main/alpine/alpine-node-dev.sh -O- | bash
```

##### Install [fnm](https://github.com/Schniz/fnm) - Fast Node Manager, similar to `nvm`

```sh
wget https://raw.githubusercontent.com/NamesMT/linux-stuff/main/alpine/scripts/install-fnm.sh -O- | sh
```

##### Install Docker

```sh
wget https://raw.githubusercontent.com/NamesMT/linux-stuff/main/alpine/scripts/install-docker.sh -O- | sh
```
You can call `sh ~/alpine.docker.service.sh` to start the docker service,  
And call `sh ~/alpine.docker.service.sh stop` to stop the docker service.

##### Install [sgerrand/alpine-pkg-glibc](https://github.com/sgerrand/alpine-pkg-glibc)

This package will help you in cases where an app requires glibc and `gcompat` doesn't work, like `Miniconda`, glibc `bun`.
```sh
wget https://raw.githubusercontent.com/NamesMT/linux-stuff/main/scripts/install-glibc.sh -O- | sh
```

#### Ubuntu:

##### `ubuntu-node-dev` dev environment setup:

Run `ubuntu-node-dev` script: *([`fnm`](https://github.com/Schniz/fnm) included to manage node version)*
```sh
wget https://raw.githubusercontent.com/NamesMT/linux-stuff/main/ubuntu/ubuntu-node-dev.sh -O- | bash
```

#### Arch:

##### `arch-init` Arch initialization script:

This script will help you do some initial setup for an Arch Linux installation, like: updating databases (key, packages), updating all packages, create a new user.
```sh
export NEW_USER=yourname && curl -fsSL https://raw.githubusercontent.com/NamesMT/linux-stuff/main/arch/arch-init.sh | bash
```

##### `arch-node-dev` dev environment setup:

Run `arch-node-dev` script: *([`fnm`](https://github.com/Schniz/fnm) included to manage node version)*
```sh
curl -fsSL https://raw.githubusercontent.com/NamesMT/linux-stuff/main/arch/arch-node-dev.sh | bash
```

---

### Build:

```sh
export imageName=namesmt/linux-stuff
export imageTag= # node | node-dev | node-aws ...
docker build -f "${imageTag}.Dockerfile" -t "${imageName}:${imageTag}" "."
docker push "${imageName}:${imageTag}"
```

## Roadmap

- [x] Github Actions to automate build

## Credits:

- [theidledeveloper/aws-cli-alpine](https://github.com/theidledeveloper/aws-cli-alpine): most of starting points
