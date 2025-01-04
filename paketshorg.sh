#!/bin/sh

# Verificar si se pasó un parámetro
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <nombre_del_archivo.so>"
    exit 1
fi

# Asignar el parámetro a una variable
so_file="$1"

export TEXTDOMAIN="$(basename "$0" | sed 's/\.[^.]*$//')"
# echo "$TEXTDOMAIN"

input_string="
Search     Buscar
cat        gato
dog        perro
bird       paloma
fish       pez
horse      caballo
dinosaur   dinosaurio
butterfly  mariposa
"

po_content='msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
'
while IFS= read -r line; do
    if [[ -z "$line" ]]; then
        continue
    fi
    msgid="$(echo "$line" | awk '{print $1}')"
    msgstr="$(echo "$line" | awk '{print $2}')"
    po_content+="
msgid \"$msgid\"
msgstr \"$msgstr\"
"
done <<< "$input_string"
echo "$po_content" | msgfmt -o /usr/share/locale/es/LC_MESSAGES/paketshorg.mo -

# Nombre del archivo de la descarga
p_html="$(dirname $0)/paketshorg.html"
echo "HTML $p_html"

# wget --debug \
headers="$(wget --server-response \
	--header='user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36' \
	--header='cookie: consent_notice_agree=true; distro_id=151' \
	--content-on-error \
	-O "$p_html" \
	"https://pkgs.org/search/?q=$so_file" 2>&1)"

# Extraer el valor del header Set-Cookie y guardarlo en una variable
set_cookie="$(echo "$headers" | grep -i 'Set-Cookie:' | sed -n 's/^.*Set-Cookie: //p' | tr -d '\r')"

# Extraer y mostrar cada componente
token1="$(echo "$set_cookie" | grep -oP '^[^;]+')"

# Utiliza cut para separar el nombre de la variable y su valor
var2="$(echo "$token1" | cut -d'=' -f1 | sed -E 's/1/2/g' )"
var3="$(echo "$token1" | cut -d'=' -f1 | sed -E 's/1/3/g' )"
var_value="$(echo "$token1" | cut -d'=' -f2)"

# Utiliza pipes para invertir el valor de la variable
reversed_value="$(echo "$var_value" | rev)"

# Crear el token invertido
token2="$var2=$reversed_value"

# Mostrar tokens
# echo "Token1: $token1"
# echo "Token2: $token2"

wget \
	--header='user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36' \
	--header="cookie: $token1; $token2; consent_notice_agree=true; distro_id=151" \
	--content-on-error \
	-O "$p_html" \
	"https://pkgs.org/search/?q=$so_file" 2>/dev/null

# Search string
search="$(cat "$p_html" | grep -oP '(?<=badge badge-pill text-bg-danger">)[^<]+')"
data_keys="$(grep -oP 'data-key="\K[^"]+' "$p_html" | tr -d '\n')"
echo "Data_keys: $data_keys"

if [ -z "$search" ]; then
    echo "Abriendo HTML"
    xdg-open "$p_html"
    exit 1
fi

# Mostrar la cadena traducida
echo "$(gettext Search): $(gettext $search)"

# Mostrar imágenes y seleccionar el captcha
elegidos_texto="$($(dirname $0)/paketshorg.py "$p_html" "$search ($(gettext $search))")"
elegidos="$( echo "$elegidos_texto" | sed "s/.* //g" )"
keys=""
# Iterar sobre cada dígito en la cadena de índices
for (( i=0; i<${#elegidos}; i++ )); do
    # Obtener el dígito actual y convertirlo a índice (restar 1 porque las posiciones en bash son base 0)
    indice=$(( ${elegidos:$i:1} - 1 ))
    
    # Extraer el carácter en la posición del índice actual
    keys+="${data_keys:$indice:1}"
done

# Mostrar elegidos
token3="$var3=$keys"
echo "$elegidos_texto"
echo "Keys: $keys"
echo "Token3: $token3"
wget \
	--header='user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36' \
	--header="cookie: $token1; $token2; $token3; consent_notice_agree=true; distro_id=151" \
	--content-on-error \
	-O "$p_html" \
	"https://pkgs.org/search/?q=$so_file" 2>/dev/null

echo "Abriendo HTML"
xdg-open "$p_html"
