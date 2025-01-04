#!/bin/sh

if [ "$#" -ne 4 ]; then
    echo "Uso: $0 filtro1 filtro2 filtro3 <nombre_del_archivo.so>"
    echo "Ejemplo: $0 cooker lib64 x86_64 libXext.so.6"
    exit 1
fi

paketshorg.sh "$4" | grep -i "$1" | grep -i "$2" | grep -i "$3"
