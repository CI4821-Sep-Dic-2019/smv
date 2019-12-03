#! /bin/bash

smv() {
    FUNCTION=$1;
    case $FUNCTION in
        help)
            elixir --name client@ec2-54-89-200-226.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "Client.help()";
            ;;
        log)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --name client@ec2-54-89-200-226.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "Client.log(\"$2\", $3)";
            fi
            ;;
        update)
            if [[ $# -ne 2 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --name client@ec2-54-89-200-226.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "Client.update(\"$2\")";
            fi
            ;;
        checkout)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --name client@ec2-54-89-200-226.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "Client.checkout(\"$2\", $3)";
            fi
            ;;
        commit)
            if [[ $# -ne 4 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --name client@ec2-54-89-200-226.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix run -e "Client.commit(\"$2\", \"$3\", \"$4\")";
            fi
            ;;
        *)
            echo "Comando incorrecto"
            smv help
            ;;
    esac
};
