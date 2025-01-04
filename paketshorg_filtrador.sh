#!/bin/sh

if [ "$#" -ne 4 ]; then
    echo "Uso: $0 <nombre_del_archivo.so> filtro1 filtro2 filtro3"
    echo "Ejemplo: $0 libXext.so.6 cooker lib64 x86_64"
    exit 1
fi

paketshorg.sh "$1" | grep -i "$2" | grep -i "$3" | grep -i "$4"
