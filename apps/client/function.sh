#! /bin/bash

smv() {
    FUNCTION=$1;
    shift;
    ARGS=$1;
    shift
    for var in "$@"
    do
        ARGS="$ARGS,$var"
    done
    elixir --sname $FUNCTION -S mix run -e "Client.$FUNCTION($ARGS)";
};