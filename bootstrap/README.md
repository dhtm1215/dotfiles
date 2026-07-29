# 실행

새 환경에서는 repo 루트의 `install.sh`를 쓴다.

```bash
git clone https://github.com/dhtm1215/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

`bootstrap/install_*.sh` 파일들은 예전 OS별 보조 스크립트다. 새 설치 진입점은 `~/dotfiles/install.sh` 하나로 통일한다.
