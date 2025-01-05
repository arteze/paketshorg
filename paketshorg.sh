#!/bin/sh

# Verificar si se pasó un parámetro
if [ $# -lt 1 ]; then
	echo "Uso: $0 filtro1 filtro2 ... -i1 archivo.so (archivo a buscar)
El argumento -i1 es un número de línea una vez filtrada la salida.
Por ejemplo, si es -i1, elige la línea 1, si es -i2, la línea 2.
Esto sirve descargar los enlaces encontrados.
	
Ejemplos:
	$0 libXext.so.6
	$0 -i1 cooker lib64 x86_64 libXext.so.6
"
	exit 1
fi

show_sys(){
	# Mostrar el sistema
	# sys version arch target official pkgs urls descs
	if [[ -n $arch ]]; then
		echo -e "
+_ Version:
'$sys' > '$version' > '$arch'
$target $official"
		for pkg in "${pkgs[@]}"; do
			echo -e "
${urls[$pkg]}
'${descs[$pkg]}'
$pkg"
		done
	fi
}
random_color() {
  COLORES=(31 32 33 34 35 36 37)  # Colores de primer plano
  INDICE=$(( RANDOM % ${#COLORES[@]} ))
  echo -e "\e[${COLORES[$INDICE]}m"
}

# Obtener el último elemento del array
file_search="${@: -1}"
# echo "file_search: $file_search"

export TEXTDOMAIN="$(basename "$0" | sed 's/\.[^.]*$//')"
# echo "$TEXTDOMAIN"

input_string="
Search     Buscar
cat        gato
dog        perro
bird       ave
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
# echo "HTML $(realpath $p_html)"

user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36"

# wget --debug \
headers="$(wget --server-response --content-on-error \
	-O "$p_html" \
	--header='user-agent: $user_agent' \
	--header='cookie: consent_notice_agree=true; distro_id=151' \
	"https://pkgs.org/search/?q=$file_search" 2>&1)"

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

wget --content-on-error \
	-O "$p_html" \
	--header='user-agent: $user_agent' \
	--header="cookie: $token1; $token2; consent_notice_agree=true; distro_id=151" \
	"https://pkgs.org/search/?q=$file_search" 2>/dev/null

# Search string
search="$(cat "$p_html" | grep -oP '(?<=badge badge-pill text-bg-danger">)[^<]+')"
data_keys="$(grep -oP 'data-key="\K[^"]+' "$p_html" | tr -d '\n')"
# echo "Data_keys: $data_keys"

if [ -z "$search" ]; then
	echo "HTML Guardado en '$p_html'"
	echo "Saliendo..."
	# xdg-open "$p_html"
	# exit 1
fi

# Mostrar la cadena traducida
echo "$(gettext Search): $(gettext $search)"

# Mostrar imágenes y seleccionar el captcha
elegidos_texto="$($(dirname $0)/paketshorg.py "$p_html" "$search ($(gettext $search))")"
elegidos="$( echo "$elegidos_texto" | sed "s/.* //g" )"
# echo "Elegidos: $elegidos"
keys=""
# Iterar sobre cada dígito en la cadena de índices
for (( i=0; i<${#elegidos}; i++ )); do
	# Obtener el dígito actual y convertirlo a índice
	indice="$((${elegidos:$i:1}))"

	# Extraer el carácter en la posición del índice actual
	keys+="${data_keys:$indice:1}"
done

# Mostrar elegidos
token3="$var3=$keys"
# echo "Elegidos: $elegidos"
# echo "Keys: $keys"
# echo "Token3: $token3"
wget --content-on-error \
	-O "$p_html" \
	--header='user-agent: $user_agent' \
	--header="cookie: $token1; $token2; $token3; consent_notice_agree=true; distro_id=151" \
	"https://pkgs.org/search/?q=$file_search" 2>/dev/null

accordion="$(
	cat "$p_html" 2>&1 | grep -Ev "</?header" | grep -Ev "</?nav|section|footer" \
	| xmllint --html --xpath '//*[@id="tab-files-accordion"]' - 2>/dev/null
)"

card_exists=0
IFS=$'\n' read -rd '' -a lines <<<"$accordion"
for line in "${lines[@]}"; do
	if echo "$line" | grep -q '<div class="card"'; then
		card_exists=1
		text_cards+=("$(printf "%s\n" "${card[@]}")")
		card=()
	fi
	if [[ "$card_exists" == 1 ]];then
		card+=("$line")
	fi
done
text_cards+=("$(printf "%s\n" "${card[@]}")")
cards=()

ocard="\n Hay ${#text_cards[@]} sistemas Linux."
for card in "${text_cards[@]}"; do
	# ocard="$ocard\n$card"
	# ocard="$ocard\n"

	# Convertir contenido HTML a un array de líneas
	IFS=$'\n' read -rd '' -a lines <<<"$card"

	# Variables temporales para almacenar datos de la arquitectura actual
	sys=""
	version=""
	arch=""
	official=""
	target=""
	pkgs=()

	# Iterar sobre cada línea del contenido HTML
	for line in "${lines[@]}"; do
		if [[ $line =~ class=\"card-header\ distro-([^\"]+)\" ]]; then
			sys=${BASH_REMATCH[1]}
			target="$(echo "$line" | grep -oP 'data-bs-target="#tab-files-distro-\K[^"]+')"
		elif [[ $line =~ \<a\ class=\"card-title\"\ href=\"#\"\>([^\<]+)\<\/a\> ]]; then
			version=${BASH_REMATCH[1]}
		elif [[ $line =~ class=\"fw-bold\ ps-3\" ]]; then
			# Mostrar el sistema anterior
			ocard="$ocard$(show_sys sys version arch target official pkgs urls descs)"

			# Reiniciar variables para la nueva arquitectura
			arch="$(echo "$line" | awk -F'class="fw-bold ps-3" colspan="2">' '{print $2}' | sed -E 's/[[:space:]]+$//g')"
			official=""
			pkgs=()
			declare -A urls
			declare -A descs
		elif [[ $line =~ \<span\ class=\"badge\ badge-pill\ text-bg-success\ align-top\ d-none\ d-md-inline-block\ ms-2\"\>([^\<]+)\<\/span\> ]]; then
			official=${BASH_REMATCH[1]}
		elif [[ $line =~ href=\"([^\"]+)\" ]]; then
			href=${BASH_REMATCH[1]}
			innerHTML=$(echo "$line" | awk -F'<a href="[^"]+">' '{print $2}' | awk -F'</a>' '{print $1}')
			pkgs+=("$innerHTML")
			urls["$innerHTML"]="$href"
		elif [[ $line =~ \"d-none\ d-md-table-cell\" ]]; then
			descs["$innerHTML"]="$(
				echo "$line" \
				| awk -F'class="d-none d-md-table-cell">' '{print $2}' \
				| awk -F'</td>' '{print $1}'
			)"
		fi
	done

	# Mostrar la última arquitectura
	ocard="$ocard$(show_sys sys version arch target official pkgs urls descs)"
done

#echo -e "$ocard"

# Filtrados con grep
ocard_filtered="$ocard"
for ((i=1; i<$#; i++)); do
	if [[ ! "${!i}" =~ ^-i[0-9_]+$ ]]; then
		ocard_filtered="$(echo -n "$ocard_filtered" | grep -i "${!i}" )"
		color_aleatorio="$(obtener_color_aleatorio)"
		# echo -e "$random_color -- ${!i} --
# $ocard_filtered
# \e[0m"
	fi
done
# echo "Filtrado: $ocard_filtered"

# Filtrado de número de línea
for arg in "$@"; do
	if [[ "$arg" =~ ^-i([0-9]+)$ ]]; then
		i="$( echo "$arg" | sed 's/^-i0*//' )"
		if [[ -z "$i" ]]; then
			i=0
		fi
		line="$( echo -e "$ocard_filtered" | head -n$i | tail -n1 )"
	fi
done

echo "$line"
