# Usage
DO NOT write anything matching the regex on the next line into your notes. YOU HAVE BEEN WARNED!!! (explanation in the note_store format)
`^<note [0-9]+(/)>$`

note list
     ls
    list all availible notes by their id, date of last change and their title
note take
    open $EDITOR and add the note to $note_store
note view <n>
     show <n>
    view note with id n in $PAGER
note edit <n>
    opens note with id n in $EDITOR and updates some metadata
note delete <n>
     rm <n>
    delete note with id n

# Installation
1. Drop the script somewhere in $PATH. 
2. Make it executable. 
3. Check for variables to be to your needs. 
4. Profit.

# $note_store format
```
...
<note $id>              # $id is numeric, aka matches the regex [0-9]+
date:$date              # date and time of last modification
title: $title           # $title is a human-readable to find notes
$CONTENT                # starts by default with a newline. See $template.
<note $id/>
...
```

# optional issues
I probably won't fix any of these unless I'm really bored. I will however accept patches.
* recover tmp files from crashed $EDITOR
* moar options on sorting, display, metadata, ...
* cleanup useless uses of cat and echo (will only fix when patch provided)
* all texts into variables for easier internationalization
* add git-suport
