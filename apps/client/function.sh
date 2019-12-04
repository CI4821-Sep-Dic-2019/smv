#! /bin/bash

if [[ "${HOST}" ]]; then
  SET_NAME="--sname client"
  export DNS=dns@${HOST} 
  CMD="elixir ${SET_NAME} -S mix run -e "
else
  HOST="ec2-54-89-200-226.compute-1.amazonaws.com"
  SET_NAME="--name client@${HOST}"
  export DNS=dns@${HOST} 
  CMD="elixir ${SET_NAME} --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "
fi

smv() {
    FUNCTION=$1;
    case $FUNCTION in
        help)
            $CMD "Client.help()";
            ;;
        log)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                $CMD "Client.log(\"$2\", $3)";
            fi
            ;;
        update)
            if [[ $# -ne 2 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                $CMD "Client.update(\"$2\")";
            fi
            ;;
        checkout)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                $CMD "Client.checkout(\"$2\", $3)";
            fi
            ;;
        commit)
            if [[ $# -ne 4 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                $CMD "Client.commit(\"$2\", \"$3\", \"$4\")";
            fi
            ;;
        *)
            echo "Comando incorrecto"
            smv help
            ;;
    esac
};
