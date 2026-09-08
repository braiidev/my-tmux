# p10k_colors.zsh — armoniza el prompt de zsh (powerlevel10k) con el tema de
# tmux activo. Se versiona en el repo my-tmux y se auto-actualiza con update.sh;
# el .p10k.zsh solo hace source de este archivo.
#
# Parsa <repo>/themes/current + themes/<tema>.conf y remapea los
# POWERLEVEL9K_*_FOREGROUND de los segmentos clave usando los roles del tema:
#   marco helpers nav clima texto
#
# Si el tema no se parsea, usa defaults estilo alto_contraste (5/7/2/5/5).

function() {

  # Resolver el directorio real de este archivo (zsh: ${(%):-%x} ya es la ruta).
  local self=${(%):-%x}
  local self_dir=$self:h

  # El archivo vive en <repo>/zsh/ → themes está en <repo>/themes/
  local themes_dir=$self_dir:h/themes

  # Defaults (clasico): marco=6 texto=7 clima=2 helpers=3 nav=6
  local -i marco=6 texto=7 clima=2 helpers=3 nav=6

  local cur_name
  # themes/current puede no existir (gitignored) → usar clasico por defecto.
  if [[ -r "$themes_dir/current" ]]; then
    cur_name=$(<"$themes_dir/current")
    cur_name=${cur_name%%[$'\n\r']}
  fi
  cur_name=${cur_name:-clasico}

  local conf="$themes_dir/$cur_name.conf"
  if [[ -r "$conf" ]]; then
    # La primera linea de comentario trae los roles: marco=X texto=Y clima=Z helpers=W nav=V
    local line
    line=$(grep -m1 '^#.*marco=' "$conf" 2>/dev/null)
    if [[ -n "$line" ]]; then
      # Los roles vienen como "marco=MAGENTA(5) texto=WHITE(7) ..." → extraer solo
      # el número. Usamos sed para ignorar el nombre y el paréntesis (que en zsh
      # se interpretaría como glob).
      local num
      for key in marco texto clima helpers nav; do
        num=$(printf '%s\n' "$line" | sed -n "s/.*${key}=[A-Za-z]*\(([0-9]*)\).*/\1/p" | tr -d '()')
        [[ "$num" =~ ^[0-9]+$ ]] && : "$key=$num"
        case "$key" in
          marco)   [[ "$num" =~ ^[0-9]+$ ]] && marco=$num   ;;
          texto)   [[ "$num" =~ ^[0-9]+$ ]] && texto=$num   ;;
          clima)   [[ "$num" =~ ^[0-9]+$ ]] && clima=$num   ;;
          helpers) [[ "$num" =~ ^[0-9]+$ ]] && helpers=$num ;;
          nav)     [[ "$num" =~ ^[0-9]+$ ]] && nav=$num     ;;
        esac
      done
    fi
  fi

  # Exponer como variables globales (por si se quieren usar en otro lado).
  typeset -g TMUX_MARCO=$marco
  typeset -g TMUX_TEXTO=$texto
  typeset -g TMUX_CLIMA=$clima
  typeset -g TMUX_HELPERS=$helpers
  typeset -g TMUX_NAV=$nav

  # ---------------------------------------------------------------------------
  # Remapeo de segmentos clave de powerlevel10k.
  # Las variables ya fueron definidas hardcoded por .p10k.zsh; al estar este
  # source al cierre del bloque, estas asignaciones pisan las anteriores.
  # ---------------------------------------------------------------------------

  # prompt_char: OK -> nav, ERROR -> helpers
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$nav
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$helpers

  # dir: default y anchor -> nav, shortened -> helpers
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$nav
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$nav
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$helpers

  # time -> clima
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$clima

  # vcs (fallback cuando gitstatusd no aplica) -> clima / helpers / nav
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$clima
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$clima
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$helpers
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=$clima
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=$texto

  # status -> helpers (estados de error), clima (ok/pipe)
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=$clima
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$helpers
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$helpers
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$helpers

  # command_execution_time -> helpers
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$helpers

  # background_jobs -> nav
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$nav

  # os_icon -> nav
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=$nav

  # ---------------------------------------------------------------------------
  # Redefinir my_git_formatter para que use los colores del tema.
  # Mapeo: clean->clima, modified->helpers, untracked->nav, conflicted->helpers,
  #        meta->texto.
  # ---------------------------------------------------------------------------

  # Replicamos el formatter original, reemplazando solo los colores inline.
  typeset -g _tmux_meta="%${texto}F"
  typeset -g _tmux_clean="%${clima}F"
  typeset -g _tmux_modified="%${helpers}F"
  typeset -g _tmux_untracked="%${nav}F"
  typeset -g _tmux_conflicted="%${helpers}F"

  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      local meta=$_tmux_meta
      local clean=$_tmux_clean
      local modified=$_tmux_modified
      local untracked=$_tmux_untracked
      local conflicted=$_tmux_conflicted
    else
      local meta=$_tmux_meta
      local clean=$_tmux_meta
      local modified=$_tmux_meta
      local untracked=$_tmux_meta
      local conflicted=$_tmux_meta
    fi

    local res

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      (( $#branch > 32 )) && branch[13,-13]=".."
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG
          && -z $VCS_STATUS_LOCAL_BRANCH
        ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      (( $#tag > 32 )) && tag[13,-13]=".."
      res+="${meta}#${clean}${tag//\%/%%}"
    fi

    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
    fi

    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
      res+=" ${modified}wip"
    fi

    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )); then
      (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}<${VCS_STATUS_COMMITS_BEHIND}"
      (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
      (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}>${VCS_STATUS_COMMITS_AHEAD}"
    elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      :
    fi

    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}<-${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}->${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    (( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
    [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}-"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  # Limpiar temporales internos que ya no hacen falta en el scope global.
  unset _tmux_meta _tmux_clean _tmux_modified _tmux_untracked _tmux_conflicted
}
