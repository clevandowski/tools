#!/bin/bash
#
#
# Exemple d'utilisation avec testRemoteExecSuccess.sh
#
# remoteExec.sh -s testRemoteExecSuccess.sh -a "-s toto titi tata" -v "user01@host01 user02@host02"
#
# -s testRemoteExecSuccess.sh
#       Script local a executer en remote
# -a "-s toto titi tata"
#       Arguments à passer au script en remote
# -v "user01@host01 user02@host02"
#       Liste des user@hostname cibles
 
function help {
  echo ""
  echo "Usage: $0 -s <Script a executer> -a <\"Liste des arguments entre guillemets\"> -v <\"Liste des user@hostname cibles entre guillemets\"> [-V] [-q]"
  echo ""
  echo "    -s: Script a executer en remote"
  echo "    -a: Liste des arguments a passer au script en remote. Les arguments doivent etre entoures de guillemets pour eviter les confusions avec les arguments de $0"
  echo "    -v: Liste des user@host sur lesquels executer le script en remote. Les user@host doivent etre entoures de guillemets pour eviter les confusions avec les arguments de $0"
  echo "    -V: Mode verbose (experimental). Active l'option de debuggage -x sur le bash execute en remote"
  echo "    -q: Quiet mode. N'affiche pas le stdout du script execute en remote"
  echo "    -k: Keep logs. Conserve les fichiers de sortie d'execution du script sur la machine locale"
  echo "    -S: sudo mode. L'utilisateur doit avoir les privileges requis sur la machine hote"
}
 
 
function process_params {
  VERBOSE=false
  QUIET=false
  KEEP_LOGS=false
  SUDO_MODE=false
 
  while getopts "s:a:v:VthqkS" option; do
    case $option in
      s)
        SCRIPT=$OPTARG
       
        # Si le chemin du script a executer n'est pas absolu
        if ! echo $SCRIPT | grep "^/" >/dev/null; then
          # On se base sur le chemin du script remoteExec pour deduire le chemin du script a executer en remote
          #
          # dirname $0 : repertoire contenant le script courant
          # sed -e "s/^\.\/\(.*\)$/\1/" : On vire le motif "./" si c'est un chemin relatif (en fonction de la commande passée)
          CURRENT_SCRIPT_DIR=`dirname $0 | sed -e "s/^\.\/?\(.*\)$/\1/"`
          echo "[$HOSTNAME] CURRENT_SCRIPT_DIR=$CURRENT_SCRIPT_DIR"
          # Si le repertoire du script courant est absolu (commence par "/")
          # On ajoute $PWD/ devant
          # Note: Attention test qui nécessite [[ ]]
          if [[ "$CURRENT_SCRIPT_DIR" == /* ]]; then
            # Chemin absolu
            SCRIPT=$CURRENT_SCRIPT_DIR/$SCRIPT
          else
            # Chemin relatif
            if [[ "$CURRENT_SCRIPT_DIR" == "." ]]; then
              # Si le script est dans le repertoire courant
              SCRIPT=$PWD/$SCRIPT # Pour eviter d'avoir /chemin/./script.sh
            else
              # Si le script est dans un repertoire dir1/dir2/script
              SCRIPT=$PWD/$CURRENT_SCRIPT_DIR/$SCRIPT
            fi
          fi       
        fi
       
        echo "[$HOSTNAME] Script to execute: $SCRIPT"
        ;;
      a)
        ARGS=$OPTARG
        echo "[$HOSTNAME] List of Args: $ARGS"
        ;;
      v)
        USER_AT_HOSTS=$OPTARG
        echo "[$HOSTNAME] List of user@host: $USER_AT_HOSTS"
        ;;
      V)
        VERBOSE=true
        echo "[$HOSTNAME] Verbose mode activated"
        ;;
      q)
        QUIET=true
        echo "[$HOSTNAME] Quiet mode activated"
        ;;
      t)
        USE_TTY=true
        echo "[$HOSTNAME] TTY mode activated"
        ;;
      k)
        KEEP_LOGS=true
        echo "[$HOSTNAME] Keep logs activated"
        ;;
      S)
        SUDO_MODE=true
        echo "[$HOSTNAME] Sudo mode activated"
        ;;
      h)
        help
        exit 0
        ;;
      :)
        echo "[$HOSTNAME] L'option $OPTARG requiert un argument"
        help
        exit 1
        ;;
      \?)
        echo "[$HOSTNAME] $OPTARG: option invalide"
        help
        exit 1
        ;;
    esac
  done
 
  shift $((OPTIND-1))
 
  if [ ! -f "$SCRIPT" ]; then
    echo "Le script est obligatoire et doit etre un fichier existant"
    help
    exit 1
  fi
 
  if [ -z "$USER_AT_HOSTS" ]; then
    echo "Passez au moins un user@host cible"
    help
    exit 1
  fi
}
 
function remote_exec {
 
  local LOG_SUFFIX=$(date +%Y%m%d_%H%M%S)
 
  for USER_AT_HOST in $USER_AT_HOSTS; do
    echo "[$HOSTNAME] Starting script \"$SCRIPT $ARGS\" on $USER_AT_HOST..."
   
    if [ "$VERBOSE" = "true" ]; then
      REMOTE_COMMAND="bash -x -s -- $ARGS"
    else
      REMOTE_COMMAND="bash -s -- $ARGS"
    fi
    #echo "[$HOSTNAME] Remote command: $REMOTE_COMMAND"
   
    SSH_OPTIONS=
    if [ "$USE_TTY" = "true" ]; then
      SSH_OPTIONS="$SSH_OPTIONS -tt"
    fi
 
    if [ "$QUIET" = "true" ]; then
      ssh $SSH_OPTIONS $USER_AT_HOST $REMOTE_COMMAND < "$SCRIPT" 1>/dev/null 2>/dev/null &
#   elif [ "$VERBOSE" = "true" ]; then
#     ssh $SSH_OPTIONS $USER_AT_HOST $REMOTE_COMMAND < "$SCRIPT"
    else
      ssh $SSH_OPTIONS $USER_AT_HOST $REMOTE_COMMAND < "$SCRIPT" >$USER_AT_HOST.$LOG_SUFFIX.log 2>&1 &
    fi
    _returnedCode=$?
 
    if [ $_returnedCode -eq 0 ]; then
      echo "[$HOSTNAME] Starting script \"$SCRIPT $ARGS\" on $USER_AT_HOST... OK"
    else
      echo "[$HOSTNAME] Starting script \"$SCRIPT $ARGS\" on $USER_AT_HOST... FAILED"
    fi
  done

  echo "Waiting for all scripts ending to write report..."
  wait
  echo "All scripts finished, writing report..."
 
  for USER_AT_HOST in $USER_AT_HOSTS; do
    echo "###########################################"
    echo "# Start of stdout/stderr of $USER_AT_HOST #"
    cat $USER_AT_HOST.$LOG_SUFFIX.log
    echo "# End of stdout/stderr of $USER_AT_HOST #"
    echo "#########################################"
   
    if [ "$KEEP_LOGS" = "false" ]; then
      rm $USER_AT_HOST.$LOG_SUFFIX.log
    fi
  done
}
 
process_params "$@"
remote_exec
