
extn=`echo $1 | sed 's/,/\\\|/g'`
ip=$2
remotepath=$3
hashtable="/Users/dinesh-6810/Desktop/Work/bin/hash.table"
interval=2
path=$PWD


getModifiedFilePath()
{
    echo $1 | sed 's/\//\\\//g'
}

delete()
{
    mod=`getModifiedFilePath $1`
    sed -i '' -E "s/$mod(.*)//g" $hashtable
    sed -i '' -E '/^$/d' $hashtable
}

put() 
{
    delete $1
    echo $1 $2 >> $hashtable
}

get()
{
    cat $hashtable | grep $1 | awk {'print $2'}
}

getFiles()
{
    find $path | grep -e "\.\($extn\)"
}

transferFile()
{
    echo "Change detected -----> $filename ----> $changedpath\n\n\n"
    mod=`getModifiedFilePath $path`
    remotemod=`getModifiedFilePath $remotepath`

    filename=$1    
    changedpath=`echo $filename | sed "s/$mod/$remotemod/g"`
    
    scp $i sas@$ip:$changedpath

    echo "\n\n"
}

compare()
{
    files=`getFiles`

    for i in $files 
    do 
        filesha=`cat $i | shasum | awk {'print $1'}`
        existingsha=`get $i`

        if [[ $filesha != $existingsha ]]
        then 

            put $i $filesha
            transferFile $i
        fi
    done
}

initialSync()
{
    rm $hashtable
    touch $hashtable

    files=`getFiles`

    for i in $files 
    do    
        filesha=`cat $i | shasum | awk {'print $1'}`
        put $i $filesha
    done 

    echo "REMOTE PATH : $remotepath"

    scp -r $path/* sas@$ip:$remotepath
}

run()
{
    while true
    do 
        compare
        sleep $interval
    done
}

if [[ $# < 3 ]]
then 
    echo "Usage filemon [Extensions to be monitored] [Remote - IP] [Remote Path]"
    echo "Example :  filemon \"c,sh,java\" 172.20.25.233 /home/sas/dinesh "
    exit
fi

initialSync
run