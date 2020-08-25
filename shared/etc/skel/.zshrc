set -u               # Undefined variables are an error.

ZDOTDIR=~/.zsh       # Store all zsh-related stuff in ~/.zsh/ instead of ~/

### Setup PATH
##############
typeset -U path  # No duplicates
path=()

# On some other systems /usr/bin links to /bin; use the full path to prevent dupes.
_prepath() {
	for dir in "$@"; do
		dir=${dir:A}
		[[ ! -d "$dir" ]] && return
		path=("$dir" $path[@])
	done
}
_postpath() {
	for dir in "$@"; do
		dir=${dir:A}
		[[ ! -d "$dir" ]] && return
		path=($path[@] "$dir")
	done
}

_prepath /bin /sbin /usr/bin /usr/sbin /usr/games
_prepath /usr/pkg/bin   /usr/pkg/sbin   # NetBSD
_prepath /usr/X11R6/bin /usr/X11R6/sbin # OpenBSD
_prepath /usr/local/bin /usr/local/sbin

_postpath "/usr/lib/psql12/bin/"       # PostgreSQL 12 on Void
_postpath "$HOME/.cache/go-path/bin"   # Go
_postpath "$HOME/.vim/pack/plugins/start/gopher.vim/tools/bin"
_prepath  "$HOME/.local/bin"           # My local stuff.
if [[ -d "$HOME/.gem/ruby" ]]; then    # Ruby
	for d in "$HOME/.gem/ruby/"*; do
		_postpath "$d/bin";
		export BUNDLE_PATH=$d  # Because bundler is stupid.
	done
fi

unfunction _prepath
unfunction _postpath

### Various env variables
#########################
[[ -n "${TMUX:-}" ]] && export TERM=screen-256color || export TERM=st-256color

# Helper; will be unset later.
_exists() { (( $+commands[$1] )) }

_exists vim      && export EDITOR=vim        # Default applications.
_exists firefox  && export BROWSER=firefox
_exists less     && export PAGER=less

# Store stuff in ~/.config and ~/.cache when we can.
# https://github.com/grawity/dotfiles/blob/master/.dotfiles.notes
# https://www.reddit.com/r/zsh/comments/fvtr19/no_more_dotfile_clutter_in_my_home/
export LESSHISTFILE=~/.cache/lesshistory
export INPUTRC=~/.config/inputrc
export SQLITE_HISTORY=~/.cache/sqlite_history
export PSQLRC=~/.config/psqlrc
export PSQL_HISTORY=~/.cache/psql_history
export BUNDLE_USER_HOME=~/.cache/bundle
export GNUPGHOME=~/.config/gnupg
# GTK: $XDG_CONFIG_HOME/gtk-3.0/Compose
export XCOMPOSEFILE=~/.config/x11/compose
export XAUTHORITY=~/.config/x11/authority

# Doesn't work? "startx ~/.config/x11/xinitrc"?
# TODO export XINITRC=~/.config/x11/xinitrc
# TODO export VIMINIT=":source ~/.config/vim/vimrc"
# TODO export GEM_HOME=~/.cache/gem

export LANG=en_NZ.UTF-8                      # Use Kiwiland for sane date format, metric system, etc.
export GOPATH=~/.cache/go-path               # Mostly just cache files etc. now we have modules.
export GOTMPDIR=/tmp/gotmpdir                # Store Go tmp files in /tmp; make sure it exists as Go won't create it.
[[ ! -d "$GOTMPDIR" ]] && mkdir "$GOTMPDIR"

# R    Display colours escape chars as-is (so they're displayed).
# i    Ignore case unless pattern has upper case chars.
# M    Display line numbers and position.
# Q    Never ring terminal bell.
# X    Don't clear the screen on exit.
# L    Ignore LESSOPEN (some Linux distros set this by broken defaults (*cough* Fedora *cough*).
export LESS="RiMQXL"

export LS_COLORS="no=00:fi=00:di=34:ln=01;31:pi=34;43:so=31;43:bd=30;43:cd=30;43:or=01;35:ex=31:"
export GREP_COLOR=31                                           # Older GNU grep; BSD grep
export GREP_COLORS="ms=31:mc=31:sl=0:cx=0:fn=0:ln=0:bn=0:se=0" # Newer GNU grep, I guess GREP_COLOR was too easy to use
export RIPGREP_CONFIG_PATH=$HOME/.config/ripgrep

export BLOCKSIZE=K                 # Output sizes in K instead of 512b blocks.
export MANWIDTH=80                 # Only needed with GNU stuff; use mandoc for better man.
#export GDK_CORE_DEVICE_EVENTS=1    # Fix scrolling in GTK3; https://www.pekwm.org/projects/pekwm/tasks/350
export GTK_IM_MODULE=xim           # Make compose key work.
export QT_IM_MODULE=xim
export GTK_OVERLAY_SCROLLING=0     # Disable annoying "overlay scrollbar".
export SYSTEMD_PAGER=              # Don't output to a pager.
if [[ -d '/etc/service' ]]; then   # Set user service dir for runit.
	export SVDIR=/etc/service
elif [[ -d '/var/service' ]]; then
	export SVDIR=/var/service
fi
export XDG_RUNTIME_DIR=/tmp/xdg-runtime-$USER  # Needed for some programs.
mkdir -p $XDG_RUNTIME_DIR

# Run commands from this file on interactive session
[[ -f "$HOME/.local/python-startup" ]] && export PYTHONSTARTUP=~/.local/python-startup

### Our work here is done if not an interactive shell
#####################################################
[[ -o interactive ]] || return 0

# Load zsh-completions
fpath=($HOME/.zsh/zsh-completions/src $fpath)

# Directory shortcuts
hash -d pack=$HOME/.cache/vim/pack/plugins/start
hash -d vim=/usr/local/share/vim/vim82
hash -d d=$HOME/code/arp242.net/_drafts
hash -d p=$HOME/code/arp242.net/_posts
hash -d go=/usr/lib/go/src
hash -d c=$HOME/code
hash -d gc=$HOME/code/goatcounter

setopt no_flow_control       # Disable ^S, ^Q, ^\
stty -ixon quit undef        # For Vim etc; above is just for zsh.
setopt notify                # Report status of bg jobs immediately
setopt no_hup                # Don't kill background jobs when exiting
setopt no_clobber            # Don't clobber existing files with >
setopt append_create         # Refuse to create new files with >>
setopt no_beep               # Don't beep
setopt no_bg_nice            # Don't frob with nicelevels
#setopt interactive_comments   # Allow comments in interactive shells
setopt no_auto_remove_slash  # Don't guess when slashes should be removed (too magic)
setopt no_match              # Show error if globbing fails
setopt extended_glob         # More globbing characters
LISTMAX=999999               # Disable 'do you wish to see all %d possibilities'

### History
setopt append_history        # Append to history, rather than overwriting
setopt inc_append_history    # Append immediately rather than only at exit
setopt extended_history      # Store some metadata as well
setopt hist_no_store         # Don't store history or fc commands
setopt no_bang_hist          # Don't use ! for history expansion
setopt hist_ignore_dups      # Don't add to history if it's the same as previous event.
setopt hist_ignore_all_dups  # Remove older event if new event is duplicate.
HISTFILE=~/.zsh/history      # Store history here
HISTSIZE=11000               # Max. entries to keep in memory
SAVEHIST=10000               # Max. entries to save to file
HISTORY_IGNORE='([bf]g *|[bf]g|disown|cd ..|cd -)' # Don't add these to the history file.

### Prompt
setopt prompt_subst          # Expand parameters commands, and arithmetic in PROMPT

# Set mode variable for prompt
function zle-line-init zle-keymap-select {
	mode="${${KEYMAP/vicmd/n}/(main|viins)/i}"
	zle reset-prompt
}
zle -N zle-line-init; zle -N zle-keymap-select

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git       # Enable just git.
zstyle ':vcs_info:*' formats '(%b)'   # Show branch.

set_prompt() {
	vcs_info >/dev/null 2>&1

	print -n "%(?..%130(?..%S%?%s))"           # Exit code in "standout" if non-0 and non-130 (^C to clear input)
	[[ "${mode:-}" = n ]] && print -n "%S"     # Directory as "standout" in normal mode.
	print -n "[%~]${vcs_info_msg_0_:-}%#"      # Directory and VCS info (if any).
	[[ "${mode:-}" = "n" ]] && print -n "%s"   # End standout.
	print -n ' '
}

set_rprompt() {
	local host='%U%B%m%b%u'
	if [[ -n "${SSH_CLIENT:-}${SSH2_CLIENT:-}${SSH_CONNECTION:-}" ]]; then
		host="%F{red}${host}%f"
	fi
	print "${host}:%T"
}

PROMPT=$'$(set_prompt)'
RPROMPT=$'$(set_rprompt)'


### Completion
##############
setopt complete_in_word      # Allow completion from within a word/phrase.
setopt always_to_end         # Move cursor to end of word when when completing from middle.
setopt no_list_ambiguous     # Show options on single tab press.
# setopt path_dirs


# Load and init
autoload -U compinit && compinit  # Load completion system.
zmodload zsh/complist             # Load interactive menu.

zstyle ':completion:*' menu select                      # Use menu for selecting.
zstyle ':completion::complete:*' use-cache on           # Enable cache (not used by many completions).
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # Make completion case-insensitive.
zstyle ':completion:*:warnings' format 'No completions' # Warn when there are no completions
zstyle ':completion:*:functions' ignored-patterns '_*'  # Ignore in completion.
zstyle ':completion:*:*files'    ignored-patterns '*?.pyc' '*?.o'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}  # Show ls-like colours in file completion.
zstyle ':completion:*' squeeze-slashes true             # "path//<Tab>" is "path/" rather than "path/*"

# ????
#zstyle ':completion:*' completer _expand _complete _ignored
#zstyle ':completion:*' completer _expand _complete

# Match words.
# TODO: this makes "mpla" complete to "gtste*mpla*te" – it should only match
# "mpla", "-mpla", ".mpla", etc.
# Note this base the "make case insensitive" redundant" once I fix it.
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'


### Keys
########
bindkey -v              # Use "vi" bindings.
export KEYTIMEOUT=10    # Time to wait for another key in multi-character sequences, in 1/100th second.

autoload -U up-line-or-beginning-search    && zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search  && zle -N down-line-or-beginning-search
autoload -U edit-command-line              && zle -N edit-command-line

# So ideally we should use "zmodload zsh/terminfo" and then use $terminfo for
# some of the below, but on my system various entries are missing or wrong. So
# I'll guess I'll keep the ugly stuff below(?) For reference, you can list
# terminfo with (also, infocmp):
#
#   for k v in ${(kv)terminfo}; do printf '%-10s %q\n' "$k" "$v"; done
#
bindkey '^[[A'  up-line-or-beginning-search    # Arrow up
bindkey '^[OA'  up-line-or-beginning-search
bindkey '^[[B'  down-line-or-beginning-search  # Arrow down
bindkey '^[OB'  down-line-or-beginning-search
bindkey '^[[H'  beginning-of-line              # Home
bindkey '^[[1~' beginning-of-line
bindkey '^[[7~' beginning-of-line
bindkey '^[[F'  end-of-line                    # End
bindkey '^[[4~' end-of-line
bindkey '^[[8~' end-of-line
bindkey '^[[5~' up-line-or-history             # Page up
bindkey '^[[6~' down-line-or-history           # Page down
bindkey '^[[3~' delete-char                    # Delete
bindkey '^[[P'  delete-char
bindkey '^h'    backward-delete-char           # Backspace
bindkey '^?'    backward-delete-char
bindkey '^u'    undo

bindkey '^a'    beginning-of-line              # Map some common stuff from non-Vi defaults.
bindkey '^b'    backward-char
bindkey '^e'    end-of-line
bindkey '^k'    kill-line
bindkey '^p'    up-line-or-beginning-search
bindkey '^n'    down-line-or-beginning-search

bindkey '^t'    edit-command-line              # Edit in Vim.
bindkey '^\'    accept-and-hold                # Run command without clearing commandline.
bindkey '^[[Z'  up-history                     # Shift+Tab; so it works in completion menu to go back.
bindkey '^[OP'  run-help                       # F1

# TODO: Make ^W erase path *and* /

# Add "doas" at the start.
insert-doas() { zle beginning-of-line; zle -U "doas " }
zle -N insert-doas insert-doas && bindkey '^s' insert-doas

# Replace first word with "rm".
replace-rm()  { zle beginning-of-line; zle delete-word; zle -U "rm " }
zle -N replace-rm replace-rm && bindkey '^r'    replace-rm

remember() {
	# Nothing in buffer: get previous command.
	if [[ $#BUFFER -eq 0 ]]; then
		print -ln "${stored:-}"
		stored=
	# Store current input.
	else
		stored=$BUFFER
		BUFFER=
	fi
}
zle -N remember
bindkey '^Q' remember

# Saves the current input and returns to it afterwards.
# bindkey '^Q'    push-input


       # getln [ -AclneE ] name ...
       #        Read the top value from the buffer stack and put it in the shell
       #        parameter name.  Equivalent to read -zr.

       # pushln [ arg ... ]
       #        Equivalent to print -nz.

       # get-line (ESC-G ESC-g) (unbound) (unbound)
       #        Pop the top line off the buffer stack and insert it at the
       #        cursor position.


#bindkey ' ' magic-space    # also do history expansion on space

# TODO: don't like the menu on this, but idea is nice.
#   autoload -U history-beginning-search-menu
#   zle -N history-beginning-search-menu
#   bindkey '\eP' history-beginning-search-menu

# Put job in fg on ^Z if there are any bg jobs.
# toggle-ctrl-z () {
#   if [[ $#BUFFER -eq 0 ]]; then
#     BUFFER="fg"
#     zle accept-line
#   else
#     zle push-input
#     zle clear-screen
#   fi
# }
# zle -N toggle-ctrl-z
# bindkey '^Z' toggle-ctrl-z

### Commands
############
alias cp='cp -i'              # Ask for confirmation when overwriting existing files.
alias mv='mv -i'
alias make='nice -n 20 make'  # Make can always be very nice.
alias free='free -m'          # MB is more useful.
alias cal='cal -m'            # Week starts on Monday.
alias ps='ps axu'             # These are pretty much the only flags I use.

if [[ "$(uname)" = "Linux" ]]; then
	if [ -h /bin/ls ]; then   # Assume busybox
		alias ls='ls -F --color=never'
	else
		alias ls='ls -FN --color=auto' # -F adds trailing / etc; -N avoids adding quotes
	fi
	alias lc='ls -lh'              # "List Complete"
	alias la='ls -A'               # "List All"
	alias lac='ls -lhA'            # "List All Complete"
	alias lsd='ls -ld *(-/DN)'     # "List Directory"
	alias lh='ls -d .*'            # "List Hidden"
else
	alias ls='ls -F'
	alias la='ls -a'
	alias lc='ls -l'
	alias lac='ls -la'
fi

if _exists systemctl; then
	alias zzz='systemctl suspend'
	alias ZZZ='systemctl hibernate'
elif _exists pm-suspend; then
	alias zzz='pm-suspend'
	alias ZZZ='pm-hibernate'
fi

_exists bsdtar     && alias tar='bsdtar'
_exists htop       && alias top='htop'
_exists fd         && alias fd='fd --glob'
_exists youtube-dl && alias youtube-dl='youtube-dl --no-part -o "%(title)s-%(id)s.%(ext)s"'
_exists sqlite3    && alias sqlite=sqlite3
_exists gpg2       && alias gpg=gpg2
_exists psql       && alias psql='LESS=S$LESS psql'  # Don't wrap

if _exists rg; then
	alias ag='rg'
elif _exists ag; then
	alias ag='ag -S --color-match 31 --color-line-number 35 --color-path 1\;4'
fi

# Pull:
#    remote: Enumerating objects: 25, done.                                builtin/pack-objects.c
#    remote: Counting objects: 100% (25/25), done.
#    remote: Compressing objects: 100% (10/10), done.
#    remote: Total 25 (delta 18), reused 22 (delta 15), pack-reused 0
#    Unpacking objects: 100% (25/25), 22.20 KiB | 303.00 KiB/s, done.      builtin/unpack-objects.c
# &  From github.com:vim/vim                                               builtin/ls-remote.c
# &     80a20df86..3f65c66df  master     -> origin/master                  builtin/fetch.c
# &   * [new tag]             v8.2.0831  -> v8.2.0831
# &   * [new tag]             v8.2.0832  -> v8.2.0832
# &   * [new tag]             v8.2.0833  -> v8.2.0833
# &   * [new tag]             v8.2.0834  -> v8.2.0834
# &  Updating 80a20df86..3f65c66df                                         builtin/merge.c
#    Fast-forward
#     src/ex_cmds.c                 | 3 +++
#     src/gui.c                     | 2 ++
#     src/libvterm/src/pen.c        | 4 ++--
#     src/map.c                     | 2 +-
#     src/terminal.c                | 2 +-
#     src/testdir/test_popupwin.vim | 3 +++
#     src/version.c                 | 8 ++++++++
#     7 files changed, 20 insertions(+), 4 deletions(-)

# push: show only last 2 lines:
#
#   Enumerating objects: 5, done.                                          builtin/pack-objects.c
#   Counting objects: 100% (5/5), done.
#   Delta compression using up to 2 threads
#   Compressing objects: 100% (3/3), done.
#   Writing objects: 100% (3/3), 1.24 KiB | 1.24 MiB/s, done.
#   Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
#   remote: Resolving deltas: 100% (2/2), completed with 2 local objects.  builtin/index-pack.c
# & To github.com:zgoat/zdb.git                                            transport.c
# &    117485d..cb59ca2  master -> master

# Or on new Git PR
#   Enumerating objects: 11, done.
#   Counting objects: 100% (11/11), done.
#   Delta compression using up to 2 threads
#   Compressing objects: 100% (6/6), done.
#   Writing objects: 100% (9/9), 2.77 KiB | 1.38 MiB/s, done.
#   Total 9 (delta 0), reused 0 (delta 0), pack-reused 0
#   remote:
#   remote: Create a pull request for 'c' on GitHub by visiting:
#   remote:      https://github.com/arp242/test/pull/new/c
#   remote:
# & To github.com:arp242/test.git
# &  * [new branch]      c -> c


# git() {
# 	if [[ "${1:-}" = "push" ]]; then
# 		shift
# 		/usr/bin/git push -q $@
# 	elif [[ "${1:-}" = "pull" ]]; then
# 		shift
# 		/usr/bin/git pull -q $@
# 	else
# 		/usr/bin/git $@
# 	fi
# }

# $ alias 'git push'='git push -q'
# $ alias git push
# exit 1
# $ alias 'git push'
# alias 'git push'='git push -q'



if _exists vim; then
	alias vim="vim -p"
	alias vi="vim"
fi

# Unset helper.
unfunction _exists

# Typos
alias sl='ls'
alias l='ls'
alias c='cd'
alias vo='vi'
alias ci='vi'
alias iv='vi'
alias grpe='grep'
alias Grep='grep'
alias les='less'
alias les='less'
alias Less='less'
alias cd.='cd .'
alias cd..='cd ..'

alias td='echo $(date +%Y-%m-%d)'
alias now='echo $(date +%Y-%m-%d\ %T)'

# Smarter run-help; "git commit foo" will pull up git-commit(1), not git(1).
autoload -U run-help run-help-git
alias run-help >/dev/null && unalias run-help

alias curl='noglob curl'   # Disable globbing for some commands where we rarely want it.
alias find='noglob find'

# Skip globbing the first grep argument; e.g.:
#
#   grep foo.*bar *.txt
#
# I'd like to glob the *.txt, but not the first argument. This is especially an
# issue with extendedglob, since ^ is now a globbing character.
#
# TODO: skip arguments: "grep -i pat.*pat"; current solution is to add them last:
# grep pat.*pat -i
# alias grep >/dev/null && unalias grep
# grep() {
# 	patt=$1
# 	shift
# 	# TODO: why do I need to force --color here?
# 	command grep --color=auto $patt $(eval echo $@)
# }
# TODO: add helper for the "alias to function"-pattern (need unalias to make
# source .zshrc work)
# alias grep='noglob grep'

# Get quick results for "zc 6*6", or just use "zc" to get zcalc
autoload -U zcalc
alias zc >/dev/null && unalias zc
zc() { [[ -n "$@" ]] && zcalc -e $@ || zcalc }
alias zc='noglob zc'

# Global aliases to pipe output.
# TODO: Ideally, restrict this to the end of the line.
alias -g VV=' |& vim +S -'
alias -g LL=' |& less'
alias -g GG=' |& grep'

# "ag edit" and "grep edit".
# TODO: skip flags.
age() {
	vim \
		+'/\v'"${1/\//\\/}" \
		+':silent tabdo :1 | normal! n' \
		+':tabfirst' \
		-p $(ag "$@" | cut -d: -f1 | sort -u)
}
grepe() {
	vim \
		+'/\v'"${1/\//\\/}" \
		+':silent tabdo :1 | normal! n' \
		+':tabfirst' \
		-p $(grep "$@" | cut -d: -f1 | sort -u)
}

# For copying examples.
unprompt() {
	export PS1='$ '
	export RPROMPT=' '
}

reagent() {
	export SSH_AUTH_SOCK=$(echo /tmp/ssh-*/agent.*)
	ssh-add -l >/dev/null || ssh-add
}

rnd() {
	[[ "${1:-}" = "ascii" ]] && filter='[:punct:][:space:][:cntrl]' || filter='[:space:]'
	strings -n1 < /dev/urandom | tr -d "$filter" | head -c${2:-15}
	echo
}

hashcwd() { hash -d "$1"="$PWD" }

# "tmp go"
tgo() {
	tmp="$(mktemp -p /tmp -d "tgo_$(date +%Y%m%d)_XXXXXXXX")"
	printf 'package main\n\nfunc main() {\n\n}\n' > "$tmp/main.go"
	printf 'package main\n\nfunc TestMain(t *testing.T) {\n\n}\n\n' > "$tmp/main_test.go"
	printf 'func BenchmarkMain(b *testing.B) {\n\tb.ReportAllocs()\n\tfor n := 0; n < b.N; n++ {\n\t}\n}\n' >> "$tmp/main_test.go"

	printf 'module %s\n' "$(basename "$tmp")" > "$tmp/go.mod"
	(
		cd "$tmp"
		vim -p main.go main_test.go
		echo "$tmp"
	)
}

sql() {
	cmd="psql -X -P linestyle=unicode -P null=NULL goatcounter"
	f="$HOME/docs/sql/scripts/$1"
	if [[ -f "$f" ]]; then
		eval "$cmd" < "$HOME/docs/sql/scripts/$1" | less -S
	else
		eval "$cmd" <<< "$1" | less -S
	fi
}
_sql() { _files -W ~/docs/sql/scripts }
compdef _sql sql

# Shorter cut.
cutt() { cut -f "${1}" -d "${2:- }" }

# Create/edit GoatCounter migrations without too much faffing about.
mig() {
	p="$HOME/code/goatcounter/db/migrate"

	if [[ -f "$p/pgsql/$1" ]]; then
		vim -p "$p/pgsql/$1" "$p/sqlite/$1"
		return
	fi

	name="$(date +%Y-%m-%d)-1-$1.sql"
	sql="begin;\n\n\n\tinsert into version values('${name%.sql}');\ncommit;\n"
	printf "$sql" > "$p/pgsql/$name"
	printf "$sql" > "$p/sqlite/$name"

	vim -p "$p/pgsql/$name" "$p/sqlite/$name"
}
_mig() { _files -W ~/code/goatcounter/db/migrate/pgsql }
compdef _mig mig

# Make exec refuse to run if the command doesn't exist.
#
# Note: this prints a message, which also gets printed on completion?
#
#    whence -p $1 >/dev/null && builtin exec $@ || echo >&2 "$1: command not found"
exec() { whence -p $1 >/dev/null && builtin exec $@ }

# List completions just for the PostgreSQL manpages on SQL syntax.
man-sql() {
	# TODO: check -w in any position.
	if [[ ${1:-} = "-w" ]]; then
		w=$(echo "$2" | tr '[[:upper:]]' '[[:lower:]]' | tr -d _)
		firefox "https://www.postgresql.org/docs/current/sql-$w.html"
		return
	fi

	man $@
}
_man-sql() {
	# _files -W /usr/share/man/man7 -g "[A-Z]*.7"
	#local x=(/usr/share/man/man7/[A-Z]*.7)

	local x=('-w')
	for f in /usr/share/man/man7/[A-Z]*.7; do
		f=${f%.7}
		x=($x ${f##*/})
	done

	# TODO: accept any position; add -w
	_arguments "1: :{_describe 'page' x}"
	#_arguments -s -S : $x
}
compdef _man-sql man-sql

# TODO: add "back", which is like "cd -" but goes back like browser; also "forward".
# b
# f
# b() { }
# f() { }
