#!/bin/sh

# Si no hay argumentos muestra la ayuda
if [ $# -lt 1 ]; then
	echo "Uso: $0 filtro1 filtro2 ... -i1 archivo.so (archivo a buscar)
El argumento -i1 es un número de línea una vez filtrada la salida.
Por ejemplo, si es -i1, elige la línea 1, si es -i2, la línea 2.
Con este filtro se descarga el enlace encontrado.
	
Ejemplos:
	$0 libXext.so.6
	$0 -i1 cooker lib64 x86_64 libXext.so.6
"
	exit 1
fi

show_sys(){
	# Muestra los detalles del paquete relacionado al sistema
	# sys version arch target official pkgs urls descs
	if [[ -n $arch ]]; then
		echo -e "

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
random_color() { # Genera un color aleatorio
  c=(31 32 33 34 35 36 37)  # Colores de primer plano
  echo -e "\e\x5b${c[$(( RANDOM % ${#c[@]} ))]}m"
}
b(){ # Busca y reemplaza un texto
	echo -e "$1" | grep -E "^$2" \
	| sed -E "s/$3/$4/g" \
	| sed -E "s/\s{2}/\s/g" \
	| sed -E "s/^\s+//g"
}
show_cyan(){ # Muestra el texto en color cyan
	echo -e "\e\x5b37m$1\e[0m"
}
show_bg_green(){ # Muestra el texto con fondo verde
	echo -e "\e\x5b42m$1\e[0m"
}

# Obtiene el argumento final, que es el nombre del archivo buscado
file_search="${@: -1}"
# echo "Buscar: $file_search"

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

po_content="msgid \"\"
msgstr \"\"
\"Content-Type: text/plain; charset=UTF-8\n\"
"

IFS=$'\n' read -rd '' -a lines <<<"$input_string"
for line in "${lines[@]}"; do
	msgid="$(echo "$line" | awk '{print $1}')"
	msgstr="$(echo "$line" | awk '{print $2}')"
	po_content+="
msgid \"$msgid\"
msgstr \"$msgstr\"
"
done

echo "$po_content" | msgfmt -o "/usr/share/locale/es/LC_MESSAGES/paketshorg.mo" -

# Nombre del archivo de la descarga
phtml="$(realpath $(dirname $0)/paketshorg.html)"
# echo "HTML $phtml"

user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.63 Safari/537.36"
# echo "user_agent '$user_agent'"

rm -vf "$phtml" 1>/dev/null 2>/dev/null
# wget --debug \
headers="$(wget --server-response --content-on-error \
	-O $phtml \
	--header="User-Agent: $user_agent" \
	"https://pkgs.org/search/?q=$file_search" 2>&1)"
rm -vf "$phtml" 1>/dev/null 2>/dev/null

# Extrayendo el header Set-Cookie
set_cookie="$(echo "$headers" | grep -i 'Set-Cookie:' | sed -n 's/^.*Set-Cookie: //p' | tr -d '\r')"

# Extrae los componentes de la cookie
token1="$(echo "$set_cookie" | grep -oP '^[^;]+')"

# Separa el token en el nombre y el valor
var2="$(echo "$token1" | cut -d"=" -f1 | sed -E 's/1/2/g' )"
var3="$(echo "$token1" | cut -d"=" -f1 | sed -E 's/1/3/g' )"
var_value="$(echo "$token1" | cut -d"=" -f2)"

# Da vuelta la secuencia de caracteres del valor del token
reversed_value="$(echo "$var_value" | rev)"

# Crea el token invertido
token2="$var2=$reversed_value"

# Crea los tokens 1 y 2
tokens_1_2="$token1; $token2;"

# Muestra los tokens
# echo "Token1: $token1"
# echo "Token2: $token2"
# echo "tokens_1_2: '$tokens_1_2'"

# echo -e "url_file_search 'https://pkgs.org/search/?q=$file_search'"

rm -vf "$phtml" 1>/dev/null 2>/dev/null
wget --content-on-error \
	-O "$phtml" \
 	--header="Cookie: $tokens_1_2" \
 	--header="User-Agent: $user_agent" \
	"https://pkgs.org/search/?q=libXext.so.6" 2>/dev/null
#rm -vf "$phtml" 1>/dev/null 2>/dev/null

# Extrae la palabra clave a buscar en los dibujos
search="$(cat "$phtml" | grep -oP '(?<=badge badge-pill text-bg-danger">)[^<]+')"
data_keys="$(grep -oP 'data-key="\K[^"]+' "$phtml" | tr -d '\n')"
# echo "Data_keys: $data_keys"

if [ -z "$search" ]; then
	echo "HTML Guardado en '$phtml'"
	echo "Saliendo..."
	# xdg-open "$phtml"
	exit 1
fi

# Muestra las cadenas traducidas
# echo -e "\n  $(gettext Search): $(gettext $search)"

# Permite que el usuario elija los dibujos (usa TKinter de Python)
elegidos_texto="$($(dirname $0)/paketshorg.py "$phtml" "$search ($(gettext $search))")"
elegidos="$( echo "$elegidos_texto" | sed "s/.* //g" )"
# echo "Elegidos: $elegidos"
keys=""

# Convierte cada cifra en letras a partir de las posiciones
for (( i=0; i<${#elegidos}; i++ )); do
	keys+="${data_keys:$((${elegidos:$i:1})):1}"
done

# Muestra los elegidos
token3="$var3=$keys"
# echo "Elegidos: $elegidos"
# echo "Keys: $keys"
# echo "Token3: $token3"

# Tokens 1, 2 y 3
tokens_1_2_3="$token1; $token2; $token3;"
# echo "tokens_1_2_3 '$tokens_1_2_3'"
# Descarga el HTML con los tokens resueltos
rm -vf "$phtml" 1>/dev/null 2>/dev/null
wget --content-on-error \
	-O "$phtml" \
	--header="Cookie: $tokens_1_2_3" \
	--header="User-Agent: $user_agent" \
	"https://pkgs.org/search/?q=$file_search" 2>/dev/null

# Captura el seleccionador expandible
accordion="$(
	cat "$phtml" 2>&1 | grep -Ev "</?header" | grep -Ev "</?nav|section|footer" \
	| xmllint --html --xpath '//*[@id="tab-files-accordion"]' - 2>/dev/null
)"

# Procesa el seleccionador expandible
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
# echo -e "text_cards '$text_cards'"

# Muestra los detalles de los paquetes relacionados con el sistema
ocard="\n Hay ${#text_cards[@]} sistemas Linux."
for card in "${text_cards[@]}"; do
	# echo -e "card: '$card'"
	# ocard="$ocard\n$card"
	# ocard="$ocard\n"

	# Variables para los datos del paquete actual
	sys=""
	version=""
	arch=""
	official=""
	target=""
	pkgs=()

	# Procesa el contenido del HTML
	IFS=$'\n' read -rd '' -a lines <<<"$card"
	for line in "${lines[@]}"; do
		if [[ $line =~ class=\"card-header\ distro-([^\"]+)\" ]]; then
			sys="${BASH_REMATCH[1]}"
			target="$(echo "$line" | grep -oP 'data-bs-target="#tab-files-distro-\K[^"]+')"
		elif [[ $line =~ \<a\ class=\"card-title\"\ href=\"#\"\>([^\<]+)\<\/a\> ]]; then
			version="${BASH_REMATCH[1]}"
		elif [[ $line =~ class=\"fw-bold\ ps-3\" ]]; then
			# Muestra los paquetes anteriores
			ocard="$ocard$(show_sys sys version arch target official pkgs urls descs)"

			arch="$(echo "$line" | awk -F'class="fw-bold ps-3" colspan="2">' '{print $2}' | sed -E 's/[[:space:]]+$//g')"

			# Reinicia las variables para el paquete nuevo
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
	# Mostrar los paquetes finales
	ocard="$ocard$(show_sys sys version arch target official pkgs urls descs)"
done
# echo -e "ocard '$ocard'"

# Filtra con el argumento -i usando grep
ocard_filtered="$ocard"
for ((i=1; i<$#; i++)); do
	if [[ ! "${!i}" =~ ^-i[0-9_]+$ ]]; then
		ocard_filtered="$(echo -n "$ocard_filtered" | grep -i "${!i}" | sed -E "s/\s+//g" )"
		# echo -e "$(random_color) -- ${!i} --
# $ocard_filtered
# \e[0m"
	fi
done
# echo -e "Filtrado: '$ocard_filtered'"

# Filtra el argumento -i
# echo "Argumentos antes: '$@'"
line=''
for arg in "$@"; do
	if [[ "$arg" =~ ^-i([0-9]+)$ ]]; then
		i="$( echo "$arg" | sed 's/^-i0*//' )"
		# echo "i $i"
		if [[ -z "$i" ]]; then
			i=0
		fi
		line="$( echo -e "$ocard_filtered" | head -n$i | tail -n1 )"
	fi
done
# echo "Argumentos luego: '$@'"

if ! echo -e "$line" | grep -E -q "^https?://.*" ;then
	echo "Resultado: '$line'"
	exit
fi

url_pkg="$line"

rm -vf "$phtml" 1>/dev/null 2>/dev/null
wget --content-on-error \
	-O "$phtml" \
	--header="Cookie: $tokens_1_2_3;" \
	--header="User-Agent: $user_agent" \
	"$url_pkg" 2>/dev/null

# xdg-open "$phtml"

if [[ "$( cat "$phtml" | grep -E "</?img\s(\w|\s|[\"\:\/\;\,\&\#=-])+>" )" ]];then
	echo -e "Se encontraron dibujos...
  '$phtml'
  Saliendo..."
	exit
fi

# Declara las variables de los detalles del paquete
nombre=""
descripcion=""
nota=""
kernel=""

# Procesa el HTML de los detalles del paquete y separa con "·"
t="$( cat "$phtml" \
	| sed -E 's/(\s*<!?)|(\s*(\w|-)+=)|("([^/]|[^\s])")|(")|((\/\w+|\w*\/)*>)/·/g' \
	| sed -E 's/&lt;/</g' \
	| sed -E 's/&gt;/>/g' \
	| sed -E 's/^http(.*)/·td·http\1·td·/g' \
	| grep -Ev "^[^·]" \
	| grep -Ev "^(·|\s)\w*(·|\s)*$"
)"

# echo "$t"
# exit

# Busca las tablas
# pkg_table_titles="$( b  "$t"  "·h2·"  "h2|·+|·span··badge text-bg-success align-top··"  "·" )"

# Busca los valores de la tabla del paquete
table_pkg_fields="$( b "$t"  "·th··row··" "·th··row··|·" | head -n-4 | tail -n+5 )"
table_pkg_values="$( b "$t"  "·td··text-break··[^·]"  "·td··text-break··|·" | head -n-3 )"
#echo -e "table_pkg_fields '$table_pkg_fields'"
#echo -e "table_pkg_values '$table_pkg_values'"
#exit

# Busca los valores del paquete                       |
name="$(         b "$t"  "·p··b·"                     "·p··b·|\s-.*"        )"
desc="$(         b "$t"  "·p··b·"                     ".*-\s|·"             )"
kernel="$(       b "$t"  "·td··text-break···strong·"  ".*strong·|·"         )"
dist_version="$( b "$t"  "·td··text-break···a···"     ".*break···a···|·"    )"
repo="$(         b "$t"  ".*break···a··.*··[^·]"      ".*a··[^·]*·.|··|\s$" )"
officials="$(    b "$t"  ".*ms-2··"                   ".*ms-2··|·"          )"
pkg_category="$( b "$t"  ".*mb-1··"                   ".*mb-1|·"            )"

note="$( cat "$phtml" \
	| sed -Ez 's/\n/|/g' \
	| sed -E 's/<pre class="text-break">|<\/pre>/\n/g' \
	| head -n2 | tail -n-1 \
	| sed 's/|/\n/g' \
	| sed 's/&#39;/\x27/g' \
)"
#echo -e "note
#$note
#"
#exit

# Busca las etiquetas de los repositorios con valor oficial
official="$( echo -e "$officials" | head -n1 )"
official_alt="$( echo -e "$officials" | tail -n+2 )"

# Lee los valores del paquete
readarray -t desc_fields <<< "$table_pkg_fields"
readarray -t desc_values <<< "$table_pkg_values"

# Asigna variables para los valores del paquete
pkg_rpm=""
pkg_type=""
pkg_name=""
pkg_version=""
pkg_release=""
pkg_epoch=""
pkg_arch=""
pkg_web=""
pkg_license=""
pkg_maintainer=""
pkg_size_download=""
pkg_size_installed=""

# Recorre la tabla de las descripciones del paquete
i_pkg_desc=0
for line in "${desc_fields[@]}"; do
	pkg_field="${desc_fields[$i_pkg_desc]}"
	pkg_value="${desc_values[$i_pkg_desc]}"
	# echo -e "$pkg_field $pkg_value"
	if [[ "$pkg_field"  == "Package filename" ]];    then pkg_rpm="$pkg_value";fi
	if [[ "$pkg_field"  == "Package type" ]];        then pkg_type="$pkg_value";fi
	if [[ "$pkg_field"  == "Package name" ]];        then pkg_name="$pkg_value";fi
	if [[ "$pkg_field"  == "Package version" ]];     then pkg_version="$pkg_value";fi
	if [[ "$pkg_field"  == "Package release" ]];     then pkg_release="$pkg_value";fi
	if [[ "$pkg_field"  == "Package epoch" ]];       then pkg_epoch="$pkg_value";fi
	if [[ "$pkg_field"  == "Package architecture" ]];then pkg_arch="$pkg_value";fi
	if [[ "$pkg_field"  == "Homepage" ]];            then pkg_web="$pkg_value";fi
	if [[ "$pkg_field"  == "License" ]];             then pkg_license="$pkg_value";fi
	if [[ "$pkg_field"  == "Maintainer" ]];          then pkg_maintainer="$pkg_value";fi
	if [[ "$pkg_field"  == "Download size" ]];       then pkg_size_download="$pkg_value";fi
	if [[ "$pkg_field"  == "Installed size" ]];      then pkg_size_installed="$pkg_value";fi
	i_pkg_desc="$((i_pkg_desc+1))"
done
#exit

# Busca la tabla de alternativas
pkg_alts="$( b "$t"  "·td··a··/"  "·td··a··|·+"  " " )"
pkg_alts_others="$( b "$t" "·td··d-none d-md-table-cell··"  ".*cell··|·+" | sed -Ez "s/_.*//g" )"
pkg_alts_repos="$( b "$t"  "·td··fw-bold d-none d-md-table-cell··"  ".*cell··|·|\s+$" )"

# Valores auxiliares
dist="$( echo -e "$dist_version" | sed 's/\s.*//g' )"
dist_list="$( b "$t"  "·a··dropdown-item···"  "·a··dropdown-item···" )"
dist_pkgs_link="$( echo -e "$dist_list" | grep "$dist" | sed "s/\/·.*//g" )"

# Busca la tabla Requiere
table_requires="$( b "$t"  "·td·|·tbody··text-break··"  "·td··a··|·+"  " " \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed -E "s/tbody text-break/\n/g" \
	| head -n3 | tail -n-1 \
	| sed -E "s/td text-break/\n/g" \
	| sed -E "s/\||td\s|td d-none d-md-table-cell mono\s*/\n/g" \
	| grep -v "^$" \
	| sed -Ez "s/fw-bold.*//g" \
)"
requires_length="$( echo -e $(( $( echo -e "$table_requires" | wc -l ) / 2 )) )"

# Busca la tabla Proporciona
table_provides="$( b "$t"  "·td·|·tbody··text-break··"  "·td··a··|·+"  " " \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed "s/|td d-none d-md-table-cell mono -|td fw-bold /\n/g" \
	| head -n2 | tail -n-1 \
	| sed "s/text-break/\n/g" \
	| head -n1 | tail -n-1 \
	| sed "s/|/\n/g" \
	| sed "s/^td\s*/\n/g" \
	| sed "s/^d-none d-md-table-cell mono\s*/\n/g" \
	| sed "s/^fw-bold\s*/\n/g" \
	| grep -v "^$" \
)"
provides_length="$( echo -e $(( $( echo -e "$table_provides" | wc -l ) / 2 )) )"

# Busca la tabla Enlaces
table_links="$( b "$t"  "·th·|·td··text-break··" "|" \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed "s/·th··w-25··/\n/g" \
	| head -n2 | tail -n-1 \
	| sed "s/|/\n/g" \
	| tail -n+3 \
	| sed -E "s/^(·th··row··|·td··text-break··)\s*|·//g" \
)"
links_length="$( echo -e $(( $( echo -e "$table_links" | wc -l ) / 2 )) )"
#echo -e "table_links $links_length
#$table_links"
#exit

# Busca la tabla Descargas
table_download="$( b "$t"  "·h2·|·th·|·td·" "|" \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed "s/·h2·/\n/g" \
	| head -n7 | tail -n-1 \
	| sed "s/|/\n/g" \
	| tail -n+4 \
	| sed -E "s/^(·th··_text-nowrap···row··|·td··text-break··|·th··row··)\s*|·td·|·//g" \
	| grep -v "^$" \
)"
download_length="$( echo -e $(( $( echo -e "$table_download" | wc -l ) / 2 )) )"
# echo -e "table_download $download_length
#$table_download"
# exit

# Busca el sector Cómo instalar
sector_install="$( b "$t"  "·h2·|·div··|·li·|·pre··code·" "|" \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed "s/·h2·/\n/g" \
	| head -n8 | tail -n-1 \
	| sed "s/|/\n/g" \
	| tail -n+3 \
	| sed -E "s/^(·li·|·pre··code·)|·//g" \
)"
sector_install_formatted="$( echo -e "$sector_install" \
	| sed -E "s/^#/\x20\x20/g" \
	| sed -E "s/^/\x20\x20/g" \
	| head -n2 \
)

$( echo -e "$sector_install" \
	| sed -E "s/^#/\x20\x20/g" \
	| sed -E "s/^/\x20\x20/g" \
	| head -n4 | tail -n-2 \
)
"
#echo -e "install
#$sector_install_formatted"
#exit

# Busca la tabla Archivos
table_files="$( b "$t"  "·h2·|·th·|·td·" "|" \
	| sed -Ez "s/\s*\n+\s*/|/g" \
	| sed "s/·h2·/\n/g" \
	| head -n9 | tail -n-1 \
	| sed "s/|/\n/g" \
	| tail -n+3 \
	| sed -E "s/^(·td·)|·//g" \
)"
files_length="$( b "$t"  "·h2·" "|" \
	| head -n8 | tail -n-1 \
	| sed -E "s/([^0-9])+\s*|·td·|·/\n/g" \
	| head -n4 | tail -n-2 \
)"
table_files_length="$( echo -e $(( $( echo -e "$table_files" | wc -l ) )) )"
#echo -e "table_files $files_length
#$table_files"
#exit

# Muestra los detalles recolectados del paquete
echo -e "
  Datos generales:
    Nombre del paquete: $( show_cyan "'$name'" )"
if [[ "$name" != "$pkg_name" ]] && [[ "$pkg_name" != "" ]];then
	echo -e "    Nombre alternativo: $( show_cyan "'$pkg_name'" )"
fi
echo -e "    Descripción del paquete: $( show_cyan "'$desc'" )
    Sistema operativo: $( show_cyan "'$kernel'" )
    Distribución: $( show_cyan "'$dist'" )
    Enlace de la distribución en pkgs: $( show_cyan "'$dist_pkgs_link'" )
    Versión de distribución: $( show_cyan "'$dist_version'" )
    Repositorio: $( show_cyan "'$repo'" ) \
$( show_bg_green "$( [[ "$official" ]] && echo -e \'Oficial\' || echo -e '' )" )"
if [[ "$note" != "$desc" ]];then
	echo -e "
    Nota:
      $( show_cyan "'$note'" )
"
fi
echo -e "  Datos del paquete:
    Archivo: $( show_cyan  "'$pkg_rpm'" )"
echo -e "    Tipo: $( show_cyan  "'$pkg_type'" )"
echo -e "    Versión: $( show_cyan  "'$pkg_version'" )
    Lanzamiento: $( show_cyan  "'$pkg_release'" )"
if [[ "$pkg_epoch" != "" ]];then
	echo -e "    Época: $( show_cyan "'$pkg_epoch'" )"
fi
echo -e "
    Arquitectura: $( show_cyan  "'$pkg_arch'" )
    Web: $( show_cyan "'$pkg_web'" )
    Licencia: $( show_cyan "'$pkg_license'" )
    Mantenedor: $( show_cyan "'$pkg_maintainer'" )
    Tamaño de la descarga: $( show_cyan "'$pkg_size_download'" )
    Tamaño instalado: $( show_cyan "'$pkg_size_installed'" )
    Categoría: $( show_cyan "'$pkg_category'" )
" | tail -n+2

# Cómo instalar
echo -e "$sector_install_formatted"

# Alternativas
echo -e "  Alternativas: $( show_bg_green "$( echo -e "$pkg_alts" | wc -l )" )"
mapfile -t lines <<< "$pkg_alts"
i_alts=0
for line in "${lines[@]}"; do
	i_official_alt="$( echo -e "$official_alt" \
		| sed -Ez "s/_.*//g" \
		| head -n+$(( i_alts + 1 )) \
		| tail -n-1
	)"
	echo -en "
    Paquete: $( show_cyan "'$( echo -e $line | sed 's/.*\s//g' )'" )
    Enlace: $( show_cyan "'$dist_pkgs_link$( echo -e $line | sed 's/\s.*//g' )'" )
    Versión: $( show_cyan "'$( echo -e "$pkg_alts_others" \
		| sed -Ez "s/_.*//g" \
		| head -n+$(( 2*(i_alts)+1 )) \
		| tail -n-1
	)'")
    Arquitectura: $( show_cyan "'$( echo -e "$pkg_alts_others" \
		| sed -Ez "s/_.*//g" \
		| head -n+$(( 2*(i_alts)+2 )) \
		| tail -n-1
	)'")
    Repositorio: $( show_cyan "'$( echo -e "$pkg_alts_repos" \
		| sed -Ez "s/_.*//g" \
		| head -n+$(( i_alts + 1 )) \
		| tail -n-1
	)'") $( show_bg_green "$( [[ "$i_official_alt" ]] && echo -e \'Oficial\' || echo -e '' )" )
"
	i_alts="$((i_alts+1))"
done
echo ""

# Requiere
echo -e "  Requiere: $( show_bg_green "$requires_length" )"
for ((i=0; i<requires_length; i++));do
	line_a="$( echo -e "$table_requires" | head -n$((2*i+1)) | tail -n-1 )"
	line_b="$( echo -e "$table_requires" | head -n$((2*i+2)) | tail -n-1 )"
	line_a1="$( echo -e "$line_a" | sed -E "s/\s+.*//g" )"
	line_a2="$( echo -e "$line_a" | sed -E "s/.*\s+//g" )"
	if [[ "$line_a1" == "$line_a2" ]];then
		line_a1=""
	fi
	spaces_a="$(( 35 - ${#line_a2} ))"
	spaces_b="$(( 15 - ${#line_b} ))"
	fill_a="$(printf "%${spaces_a}s" "")"
	fill_b="$(printf "%${spaces_b}s" "")"
	echo -e "    $line_a2 $fill_a $( show_cyan "$line_b" ) $fill_b $line_a1"
done
echo ""

# Proporciona
echo -e "  Proporciona: $( show_bg_green "$provides_length" )"
for ((i=0; i<provides_length; i++));do
	line_a="$( echo -e "$table_provides" | head -n$((2*i+1)) | tail -n-1 )"
	line_b="$( echo -e "$table_provides" | head -n$((2*i+2)) | tail -n-1 )"
	line_a1="$( echo -e "$line_a" | sed -E "s/\s+.*//g" )"
	line_a2="$( echo -e "$line_a" | sed -E "s/.*\s+//g" )"
	spaces_a="$(( 35 - ${#line_a2} ))"
	spaces_b="$(( 15 - ${#line_b} ))"
	fill_a="$(printf "%${spaces_a}s" "")"
	fill_b="$(printf "%${spaces_b}s" "")"
	echo -e "    $line_a2 $fill_a $( show_cyan "$line_b" )"
done
echo ""

# Enlaces
new_spaces=15
echo -e "  Enlaces: $( show_bg_green "$links_length" )"
for ((i=0; i<links_length; i++));do
	line_a="$( echo -e "$table_links" | head -n$((2*i+1)) | tail -n-1 )"
	line_b="$( echo -e "$table_links" | head -n$((2*i+2)) | tail -n-1 )"
	line_a2="$( echo -e "$line_a" )"
	spaces_a="$(( $new_spaces - ${#line_a2} ))"
	fill_a="$(printf "%${spaces_a}s" "")"
	echo -e "    $line_a2 $fill_a $( show_cyan "$line_b" )"
done
echo ""

# Descargas
echo -e "  Descargas: $( show_bg_green "$download_length" )"
for ((i=0; i<download_length; i++));do
	line_a="$( echo -e "$table_download" | head -n$((2*i+1)) | tail -n-1 )"
	line_b="$( echo -e "$table_download" | head -n$((2*i+2)) | tail -n-1 )"
	line_a2="$( echo -e "$line_a" )"
	spaces_a="$(( $new_spaces - ${#line_a2} ))"
	fill_a="$(printf "%${spaces_a}s" "")"
	echo -e "    $line_a2 $fill_a $( show_cyan "$line_b" )"
done
echo ""

# Archivos
echo -e "  Archivos: $( show_bg_green "$files_length" )"
for ((i=0; i<table_files_length; i++));do
	echo "    $( echo -e "$table_files" | head -n$((i+1)) | tail -n-1 )"
done
echo ""
