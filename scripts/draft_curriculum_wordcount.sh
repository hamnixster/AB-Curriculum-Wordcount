#! /bin/env zsh
{
    for i in Draft\ Curriculum/*.pdf;
    do
        pdftotext $i -;
    done;
} | sort | uniq | tr ' ' '\n' | tr '[:upper:]' '[:lower:]' | \
    sed "s/[\,\.??\'\"]//g" | sed "s/?$//g"| \
    tr -cd '\?\n\-\?\?a-zA-Z0-9' | sort | uniq -c | \
    awk '{print $1" "$2}' | sort -n
