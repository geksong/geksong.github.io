#!/bin/bash
# blog manange tool

crt_post(){
    curday=`date +%Y-%m-%d`
    blog_name="${curday}-${1}.markdown"
    file_name="../_posts/${blog_name}"
    now_time=`date '+%Y-%m-%d %H:%M:%S'`
    echo "创建blog ${file_name}"
    touch ${file_name}
    echo "---" >> ${file_name}
    echo "layout: post" >> ${file_name}
    echo "title: ${1}" >> ${file_name}
    echo ${now_time} >> ${file_name}
    echo "---" >> ${file_name}
    echo "" >> ${file_name}
}

if [[ "$1" == "-c" ]]
then
    crt_post $2
fi

