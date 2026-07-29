# dotfiles

새 환경에서 한 번에 세팅하는 용도.

## 설치

```bash
git clone https://github.com/dhtm1215/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./scripts/import-migration.sh
exec zsh
```

이미 패키지는 설치되어 있고 링크만 다시 걸고 싶으면:

```bash
~/dotfiles/install.sh --skip-packages
```

무엇을 바꿀지 먼저 보고 싶으면:

```bash
~/dotfiles/install.sh --dry-run
```

## 적용되는 것

- `~/.config/zsh` -> `~/dotfiles/zsh`
- `~/.zshrc` -> `~/dotfiles/zsh/zshrc`
- `~/.config/nvim` -> `~/dotfiles/nvim`
- `~/.tmux.conf` -> `~/dotfiles/tmux.conf`
- `~/.gitconfig` -> `~/dotfiles/.gitconfig`
- `~/.config/starship.toml` -> `~/dotfiles/starship.toml`
- `~/.tmux/plugins/tpm` 및 tmux 플러그인
- macOS Homebrew 패키지 목록: `Brewfile`
- iTerm2 프로필: `iterm2/DynamicProfiles/dotfiles.json`

기존 파일/디렉터리가 있으면 삭제하지 않고 `*.bak.YYYYMMDD_HHMMSS`로 백업한 뒤 링크한다.

## PC 옮기기 전 현재 머신에서 할 일

현재 Mac의 앱/터미널 설정을 repo로 다시 뽑는다.

```bash
cd ~/dotfiles
./scripts/export-migration.sh
git status --short
```

생성/갱신되는 파일:

- `Brewfile`: Homebrew formula, cask, tap 목록
- `iterm2/DynamicProfiles/dotfiles.json`: iTerm2 프로필/키맵/색상 등 portable profile 설정
- `tmux.conf`: 현재 `~/.tmux.conf`가 repo symlink가 아니면 실제 사용 중인 tmux 설정

`git diff`로 내용 확인 후 커밋/푸시하면 새 PC에서 그대로 받을 수 있다.

전체 `com.googlecode.iterm2.plist`는 최근 경로, 창 위치, 설치 UUID 같은 로컬 정보가 섞이므로 repo에 넣지 않는다.

## 새 PC에서 복원 순서

```bash
git clone https://github.com/dhtm1215/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./scripts/import-migration.sh
exec zsh
```

먼저 무엇이 바뀌는지 보고 싶으면:

```bash
./install.sh --dry-run
./scripts/import-migration.sh --dry-run
```

## 수동으로 옮길 것

아래 항목은 비밀 정보라서 repo에 넣지 않는다.

- `~/.ssh`: SSH key, `config`, known_hosts
- GPG key, 인증서, password manager export
- 각 서비스 로그인 세션, 브라우저 프로필, 2FA 복구 코드

새 PC에서는 SSH key를 새로 만들거나, 안전한 경로로 별도 이전한다.

## 지원

- macOS: Homebrew 기반 패키지 설치
- Arch/Nyarch: pacman 기반 패키지 설치
- Ubuntu/Debian 계열: apt 기반 기본 패키지 설치

Ubuntu/Debian에서 `yazi`, `starship`은 저장소 상황에 따라 수동 설치가 필요할 수 있다.
