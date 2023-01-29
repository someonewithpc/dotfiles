alias gdb="gdb -q"
alias ls='ls --color=auto'
alias xcopy='xclip -selection clipboard'
alias pikaur='pikaur --nodiff --noedit'
alias sysyadm='sudo yadm -c user.name="$(git config user.name)" -c user.email="$(git config user.email)" -c push.autoSetupRemote=true -c core.sshCommand="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes" --yadm-dir $HOME/.config/sysyadm --yadm-data $HOME/.local/share/sysyadm'

alias yay='yay --sudoloop'
