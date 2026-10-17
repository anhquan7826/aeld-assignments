set -e

filesdir="$1"
searchstr="$2"

if [ "$filesdir" = "" ] || [ "$searchstr" = "" ]; then
    exit 1
fi

if [ ! -d "$filesdir" ]; then
    exit 1
fi

num_files=`find "$filesdir" -type f | wc -l`
num_lines=`grep -r "$searchstr" "$filesdir" | wc -l`

printf "The number of files are %d and the number of matching lines are %d" $num_files $num_lines