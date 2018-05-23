#!/bin/bash

cachebase="$(cd $(dirname $0);pwd)/cache"; [ -d "$cachebase" ] || mkdir "$cachebase"
historyfile="$cachebase/history.xml"

addResult() {
    case $1 in
    C*)
        echo "<item uid='$1' arg='$2' valid='yes' autocomplete='$3' type='file'><title>Comment</title><subtitle>shiftキーを押してください - $1.txt</subtitle><icon>img/comment.png</icon><folder>$3</folder></item>"
        ;;
    *)
        local value=$(echo "$7"|xmlencode)
        echo "<item uid='$1' arg='$1' valid='yes' autocomplete='$2'><title>$3</title><subtitle>$4</subtitle><icon>img/$5</icon><folder>$6</folder><value>$value</value></item>"
        ;;
    esac
}

idm2alfred(){
    local xmlpath="$1"
    local xmlname="$(basename ${xmlpath%.xml})"
    local cachedir="$cachebase/$xmlname"; rm -rf "$cachedir" && mkdir "$cachedir" || return
    local filterxml="$cachedir/filter.xml"

    folder="/"
    while read -r line
    do
        if   [[ "$line" =~ ^\<folder  ]] ; then
            fnum=$((fnum+1))
            name=$(echo $line | sed 's|^.*name="\([^"]*\)".*$|\1|')
            pfolder="$folder"
            folder="$pfolder$name/"
            addResult "F$fnum" "$folder" "$name" "$pfolder" "folder.png" "$pfolder" ""
        elif [[ "$line" =~ ^\<"item " ]] ; then
            inum=$((inum+1));
            name=$(echo $line | sed 's|^.*name="\([^"]*\)".*$|\1|')
            pfolder="$folder"
            folder="$pfolder$name/"
        elif [[ "$line" =~ ^\<"account "  ]] ; then  account=$(echo $line|sed 's|^<[^>]*>\(.*\)</[^>]*>$|\1|')
        elif [[ "$line" =~ ^\<"password " ]] ; then password=$(echo $line|sed 's|^<[^>]*>\(.*\)</[^>]*>$|\1|')
        elif [[ "$line" =~ ^\<"item1 "    ]] ; then   item1=($(echo $line|sed 's|^<item1 name="\([^>]*\)">\(.*\)</item1>$|\1 \2|'))
        elif [[ "$line" =~ ^\<"item2 "    ]] ; then   item2=($(echo $line|sed 's|^<item2 name="\([^>]*\)">\(.*\)</item2>$|\1 \2|'))
        elif [[ "$line" =~ ^\<"url "      ]] ; then     url=($(echo $line|sed 's|^<url name="\([^>]*\)">\(.*\)</url>$|\1 \2|'))
        elif [[ "$line" =~ ^\<"e-mail "   ]] ; then   email=($(echo $line|sed 's|^<e-mail name="\([^>]*\)">\(.*\)</e-mail>$|\1 \2|'))
        elif [[ "$line" =~ \</*comment\> ]] ; then
            [ $line == "<comment></comment>" ] && continue
            cmnt=$line
            [[ $cmnt =~ ^\<comment\>  ]] && { cflag=true ; cmnt=${cmnt#<comment>} ; }
            [[ $cmnt =~ \</comment\>$ ]] && { cflag=flase; cmnt=${cmnt%</comment>}; }
            [ -n "$cmnt" ] && echo "$cmnt" >> "$cachedir/C$inum.txt"
        elif [ "$line" == "</item>" ] ; then
            addResult "I${inum}_$xmlname" "$folder" "$name"       "$pfolder"    "next.png"      "$pfolder" "$password"
            [ -n "$account"  ] && addResult "a${inum}_$xmlname" "$folder" "Account"     "$folder"     "account.png"   "$folder" "$account"
            [ -n "$password" ] && addResult "b${inum}_$xmlname" "$folder" "Password"    "$folder"     "password.png"  "$folder" "$password"
            [ -n "$item1"    ] && addResult "c${inum}_$xmlname" "$folder" "${item1[0]}" "${item1[1]}" "tag_blue.png"  "$folder" "${item1[1]}"
            [ -n "$item2"    ] && addResult "d${inum}_$xmlname" "$folder" "${item2[0]}" "${item2[1]}" "tag_green.png" "$folder" "${item2[1]}"
            [ -n "$url"      ] && addResult "e${inum}_$xmlname" "$folder" "URL"         "${url[1]}"   "favorite.png"  "$folder" "${url[1]}"
            [ -n "$email"    ] && addResult "f${inum}_$xmlname" "$folder" "E-MAIL"      "${email[1]}" "mail.png"      "$folder" "${email[1]}"
            [ -f "$cachedir/C$inum.txt" ] && addResult "C${inum}_$xmlname" "$cachedir/C$inum.txt" "$folder"
            folder="$pfolder"
            pfolder="${folder%/*/}/"
        elif [[ "$line" == "</folder>" ]] ; then
            folder="$pfolder"
            pfolder="${folder%/*/}/"
        else
            [ "$cflag" == true ] && echo "$line" >> "$cachedir/C$inum.txt"
        fi
    done < <(iconv -f SHIFT_JIS "$xmlpath" | tr -d '\r') > "$filterxml"

    echo "IDM → Alfred"
}

keepass2alfred(){
    local xmlpath="$1"
    local xmlname="$(basename ${xmlpath%.xml})"
    local cachedir="$cachebase/$xmlname"; rm -rf "$cachedir" && mkdir "$cachedir" || return
    local filterxml="$cachedir/filter.xml"

    folder="/"
    while read -r line
    do
        if   [[ "$line" =~ '<group>' ]] ; then
            category=group
            gnum=$((gnum+1)) 
        elif [[ "$line" =~ '<entry>' ]] ; then
            category=entry
            inum=$((inum+1)) 
        elif [[ "$line" =~ '<title>' ]] ; then
            name=$(echo $line|sed 's|^.*>\(.*\)</.*$|\1|')
            pfolder="$folder"
            folder="$pfolder$name/"
            [ "$category" == group ] && addResult "G${gnum}_$xmlname" "$folder" "$name" "$pfolder" "folder.png" "$pfolder" ""
        elif [[ "$line" =~ '<username>' ]] ; then username=$(echo $line|sed 's|^.*<username>\(.*\)</username>$|\1|'|xmldecode)
        elif [[ "$line" =~ '<password>' ]] ; then password=$(echo $line|sed 's|^.*<password>\(.*\)</password>$|\1|'|xmldecode)
        elif [[ "$line" =~ '<url>'      ]] ; then      url=$(echo $line|sed 's|^.*<url>\(.*\)</url>$|\1|'          |xmldecode)
        elif [[ "$line" =~ '<comment>'  ]] ; then  comment=$(echo $line|sed 's|^.*<comment>\(.*\)</comment>$|\1|'  |xmldecode)
            [ -n "$comment" ] && echo "$comment" > "$cachedir/C$inum.txt"
        elif [[ "$line" =~ '</entry>' ]] ; then
            [ "$category" == entry ] && addResult "I${inum}_$xmlname" "$folder" "$name"    "$pfolder" "next.png"     "$pfolder" "$password"
            [ -n "$username" ] && addResult "a${inum}_$xmlname" "$folder" "Account"  "$folder" "account.png"  "$folder" "$username"
            [ -n "$password" ] && addResult "b${inum}_$xmlname" "$folder" "Password" "$folder" "password.png" "$folder" "$password"
            [ -n "$username" -a -n "$password" ] && addResult "w${inum}_$xmlname" "$folder" "Account &amp; Password" "$folder" "comments.png" "$folder" "${username}__TAB__${password}"
            [ -n "$url"      ] && addResult "e${inum}_$xmlname" "$folder" "URL"      "$url"    "favorite.png" "$folder" "$url"
            [ -n "$comment"  ] && addResult "C${inum}_$xmlname" "$cachedir/C$inum.txt" "$folder"
            folder="$pfolder"
            pfolder="${folder%/*/}/"
        elif [[ "$line" =~ '</group>' ]] ; then
            folder="$pfolder"
            pfolder="${folder%/*/}/"
        fi
    done < "$xmlpath" | iconv -f UTF8 -t UTF8-MAC > "$filterxml"

    echo "KeePass → Alfred"
}

listxml(){
    pushd "$cachebase" >/dev/null
    local input="$1"
    local xmls=$(ls */filter.xml)

    echo '<?xml version="1.0"?>'
    echo '<items>'
    if [ "$input" == "" ]; then
        [ -f "$historyfile" ] && cat "$historyfile" || grep -hF "<folder>/</folder>" $xmls
    elif [[ "$input" =~ ^/ ]]; then
        grep -hF "<folder>${input%/*}/</folder>" $xmls | grep -i "<title>${input##*/}.*</title>"
    else
        grep -hi "<title>.*$input.*</title>" $xmls
    fi
    echo '</items>'
    popd >/dev/null
}

xmlencode(){
    cat | sed -e 's|\&|\&amp;|g' -e 's|<|\&lt;|g' -e 's|>|\&gt;|g' -e "s|'|\&apos;|g" -e 's|\\|\&#092;|g' -e 's||$#xd;<br/>|g'
}

xmldecode(){
    cat | sed -e 's|&amp;|\&|g' -e 's|&lt;|<|g' -e 's|&gt;|>|g' -e "s|&apos;|'|g" -e 's|&#092;|\\|g' -e 's|&#xd;<br/>||g'
}

putvalue(){
    pushd "$cachebase" >/dev/null
    local uid="$1"
    local xmls=$(ls */filter.xml)

    [[ $uid =~ ^F ]] && return
    [[ $uid =~ ^C ]] && return

    curr=$(grep -h "uid='$uid'" $xmls)
    hist=$(grep -v "uid='$uid'" "$historyfile" | head -n8)
    { echo -e "$curr\n$hist" ; } > "$historyfile"

    echo -n $(echo "$curr" | sed 's|^.*<value>\([^<]*\)</value>.*$|\1|' | xmldecode | sed 's|\\|\\\\|g')
    popd >/dev/null
}

rmhistory(){
    uid="$1"
    sed -i "" "/uid='$uid'/d" "$historyfile"
}

case "$1" in
keepass2alfred) keepass2alfred "$2" ;;
    idm2alfred) idm2alfred     "$2" ;;
          list) listxml        "$2" ;;
         value) putvalue       "$2" ;;
     rmhistory) rmhistory      "$2" ;;
esac

exit 0
