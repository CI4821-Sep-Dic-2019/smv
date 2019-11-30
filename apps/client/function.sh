#! /bin/bash

smv() {
    FUNCTION=$1;
    case $FUNCTION in
        help)
            elixir --sname client -S mix run -e "Client.help()";
            ;;
        log)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --sname client -S mix run -e "Client.log(\"$2\", $3)";
            fi
            ;;
        update)
            if [[ $# -ne 2 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --sname client -S mix run -e "Client.update(\"$2\")";
            fi
            ;;
        checkout)
            if [[ $# -ne 3 ]] || ! [[ $3 -gt 0 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --sname client -S mix run -e "Client.checkout(\"$2\", $3)";
            fi
            ;;
        commit)
            if [[ $# -ne 4 ]] ; then
                echo "Parámetros incorrectos"
                smv help
            else
                elixir --sname client -S mix run -e "Client.commit(\"$2\", \"$3\", \"$4\")";
            fi
            ;;
        *)
            echo "Comando incorrecto"
            smv help
            ;;
    esac
};
