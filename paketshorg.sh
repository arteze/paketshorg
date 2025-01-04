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
# echo "HTML $p_html"

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
# echo "Data_keys: $data_keys"

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
# echo "$elegidos_texto"
# echo "Keys: $keys"
# echo "Token3: $token3"
wget \
	--header='user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36' \
	--header="cookie: $token1; $token2; $token3; consent_notice_agree=true; distro_id=151" \
	--content-on-error \
	-O "$p_html" \
	"https://pkgs.org/search/?q=$so_file" 2>/dev/null

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

echo -e "\n Hay ${#text_cards[@]} sistemas Linux."
for card in "${text_cards[@]}"; do
    # echo "$card"
    # echo ""

	# Convertir contenido HTML a un array de líneas
	IFS=$'\n' read -rd '' -a lines <<<"$card"

	# Variables temporales para almacenar datos de la arquitectura actual
	current_sistema=""
	current_version=""
	current_arch=""
	current_official=""
	current_target=""
	packages=()

	# Iterar sobre cada línea del contenido HTML
	for line in "${lines[@]}"; do
		if [[ $line =~ class=\"card-header\ distro-([^\"]+)\" ]]; then
			current_sistema=${BASH_REMATCH[1]}
			current_target=$(echo "$line" | grep -oP 'data-bs-target="#tab-files-distro-\K[^"]+')
		elif [[ $line =~ \<a\ class=\"card-title\"\ href=\"#\"\>([^\<]+)\<\/a\> ]]; then
			current_version=${BASH_REMATCH[1]}
		elif [[ $line =~ class=\"fw-bold\ ps-3\" ]]; then
			if [[ -n $current_arch ]]; then
				# Imprimir la información de la arquitectura anterior
				echo -e "|\n+_ Version:"
				echo "'$current_sistema' > '$current_version' > '$current_arch'"
				echo "  $current_target $current_official"
				for package in "${packages[@]}"; do
					echo ""
					echo "  ${package_urls[$package]}"
					echo "  '${package_descriptions[$package]}'"
					echo "    $package"
				done
			fi
			# Reiniciar variables para la nueva arquitectura
			current_arch="$(echo "$line" | awk -F'class="fw-bold ps-3" colspan="2">' '{print $2}' | sed -E 's/[[:space:]]+$//g')"
			current_official=""
			packages=()
			declare -A package_urls
			declare -A package_descriptions
		elif [[ $line =~ \<span\ class=\"badge\ badge-pill\ text-bg-success\ align-top\ d-none\ d-md-inline-block\ ms-2\"\>([^\<]+)\<\/span\> ]]; then
			current_official=${BASH_REMATCH[1]}
		elif [[ $line =~ href=\"([^\"]+)\" ]]; then
			href=${BASH_REMATCH[1]}
			innerHTML=$(echo "$line" | awk -F'<a href="[^"]+">' '{print $2}' | awk -F'</a>' '{print $1}')
			packages+=("$innerHTML")
			package_urls["$innerHTML"]="$href"
		elif [[ $line =~ class=\"d-none\ d-md-table-cell\" ]]; then
			description=$(echo "$line" | awk -F'class="d-none d-md-table-cell">' '{print $2}' | awk -F'</td>' '{print $1}')
			package_descriptions["$innerHTML"]="$description"
		fi
	done

	# Manejar la última arquitectura
	if [[ -n $current_arch ]]; then
		echo -e "|\n+_ Version:"
		echo "'$current_sistema' > '$current_version' > '$current_arch'"
		echo "  $current_target $current_official"
		for package in "${packages[@]}"; do
			echo ""
			echo "  ${package_urls[$package]}"
			echo "  '${package_descriptions[$package]}'"
			echo "    $package"
		done
	fi
done
