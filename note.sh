#!/usr/bin/env bash

# This is note.sh, a shell script to maintain an unordered list of of notes from CLI.
# Copyright (C) 2019 Nils Stratmann
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


global_variables() {
    [[ -z $NOTE_STORE ]] && note_store="$HOME/.notes" || note_store=$NOTE_STORE
    tmp_dir="/tmp"

    [[ -z $EDITOR ]] && EDITOR="vim +3"

    ## When editing this var, make sure to also adopt regexes that 
    ## make use of this but currently have stuff hardcoded.
    template="title: 

"
    [[ -z $NOTES_CONFIG ]] && global_config="$HOME/.notes_config"  || global_config=$NOTES_CONFIG
}

error() {
    echo $@
    exit 1
}

warn() {
    echo $@
    return 1
}

error_var_unset() {
    error "\$$1 must be set for this script to work properly. e.g. write \"$1=$2\" into your .bashrc or this scripts global_variables()"
}

variables_check() {
    [[ -z $EDITOR ]] && error_var_unset EDITOR vim
    [[ -z $PAGER  ]] && error_var_unset PAGER less
}

## suffix on $1
get_tmp_file() {
    date=$(date +%F_%T)
    suf=$1
    [[ ! -z $suf ]] && suf="_$suf"
    if [[ ! -f "$tmp_dir/note_${date}$suf" ]]; then
        res="$tmp_dir/note_${date}$suf"
    else
        i=0
        while [[ -f "$tmp_dir/note_${date}${suf}_$i" ]]; do
            i=$((i + 1))
        done
        res="$tmp_dir/note_${date}${suf}_$i"
    fi
    (touch $res && chmod 600 $res && echo $res) || error "error creating files in $tmp_dir"
}

check_param() {
    [[ $(echo $1 | grep '^[0-9]+$') ]] || warn "You need to specify the numeric id of the note you wish to edit, FOUND: $1."
    [[ $(cat $note_store | grep "^<note $1>$") ]] || warn "This note does not exist."

}

## $1 := id
get_note_by_id() {
    check_param $1 || return 1
    cat $note_store | sed -n -e "/^<note $1>$/,\$p" | sed -e "/^<note $1\/>\$/,\$d" | grep -vP "^<note $1>$"
}

usage() {
cat << __EOF__
note.sh usage
note take
    opens \$EDITOR to let you take a note and gives it some metadata to help you find it later.
note list
    list notes in noteStore by id, last modification and title.
note view n
    view note from noteStore with id n with \$PAGER.
note edit n
    edit note from noteStore with id n with \$EDITOR.
note delete n
    delete note from noteStore with id n.
note [anything else]
    print this help-message.

# Variables
Variables used unless overwritten in the config are:
EDITOR
PAGER
NOTE_STORE
__EOF__
}

do_main() {
    global_variables
    [[ -f $global_config ]] && source $global_config
    variables_check

    case $1 in
        "list"|"ls")
            for i in $(cat $note_store | grep -P '^<note ([0-9])+>$' | sed -e 's/<note //g' -e 's/>//g' | sort -n); do
                    
                tmp=$(cat $note_store | grep -A 2 -P "^<note $i>$")
                cut="$(echo $tmp | awk -F'titile:' '{print $1}')"
                ## here I would like to make it more simple 
                ## but I cannot negat the possibility of "title: " being part 
                ## of the title
                title=$(echo $tmp | sed -e 's/<note [0-9]+> date:[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:]\{8\} title:\( \)\?//g')
                time_stamp=$(echo $tmp | awk -F'date:' '{print $2}' | awk -F' title:' '{print $1}' | tr _ " ")
                
                echo "$i ($time_stamp): $title"
            done
            ;;

        "view") ## note.sh view <n> to show note with id n
            # make sure $2 is o.k.
            get_note_by_id $2 | $PAGER
            ;;

        "edit")
            tmp_file=$(get_tmp_file)
            get_note_by_id $2 | tail -n +2 > $tmp_file || (rm $tmp_file && error 'error doing stuff about get_note_by_id and stuffing it into your $tmp_dir, '$tmp_dir.)
            $EDITOR $tmp_file
            ## please don't kill me after reading this.
            ## just tell me, if this is how to actually do this.
            before=$(get_tmp_file before)
            after=$(get_tmp_file after)
            cat $note_store | sed -e "/^<note $2>\$/,\$d" > $before
            cat $note_store | sed -n -e "/^<note $2\/>\$/,\$p" | tail -n +2 > $after
            cat > $note_store << __EOF__
$(cat $before)
<note $2>
date:$(date +%F_%T)
$(cat $tmp_file)
<note $2/>
$(cat $after)
__EOF__
            rm $before $after $tmp_file
            ;;

        "take")
            tmp_file=$(get_tmp_file)
            echo $template > $tmp_file
            $EDITOR $tmp_file
            i=0
            while [[ $(cat $note_store | grep "^<note $i>$") ]]; do
                i=$((i + 1))
            done
            cat >> $note_store << __EOF__
<note $i>
date:$(date +%F_%T)
$(cat $tmp_file)
<note $i/>

__EOF__
            ;;

        "delete"|"rm")
            tmp=$(cat $note_store | grep -A 2 -P "^<note $2>$")
            title=$(echo $tmp | sed -e 's/<note [0-9]+> date:[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9:]\{8\} title:\( \)\?//g')
            ts=$(echo $tmp | awk -F'date:' '{print $2}' | awk -F' title:' '{print $1}' | tr _ " ")
            echo "You are about to delete note $2 with title: \"$title\", last edited on $ts."
            echo 'Are you sure to delete this note? This cannot be undone. Type YES if you are sure.'
            read sure
            [[ $sure == "YES" ]] || exit 0
            before=$(get_tmp_file before)
            after=$(get_tmp_file after)
            cat $note_store | sed -e "/^<note $2>\$/,\$d" > $before
            cat $note_store | sed -n -e "/^<note $2\/>\$/,\$p" | tail -n +2 > $after
            cat > $note_store << __EOF__
$(cat $before)
$(cat $after)
__EOF__
            rm $before $after
            echo "deleted note $2."
            ;;

        *)
            usage && exit
            ;;
    esac
    [[ ! -z $tmp_file ]] && [[ -f $tmp_file ]] && rm $tmp_file
}

### DO NOT EDIT AFTER THIS. Edit do_main() instead. 
### Thanks for visiting my TED talk
do_main $@

