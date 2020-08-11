#!/bin/bash
#cnr - Compile and Run

#Setting up variables

name=$(basename "$0")
term=".cpp"
things=""
files=( )
position=1
mainfile="./main"
valgrind_cmd=""
non_recursive=""
no_remove=false
no_run=false
my_args=""
gcclib=""
compiler="g++ -std=c++17"
time_cmd=""
err_redir=""

if [ "$name" == "cnrc" ]; then
	compiler="gcc"
	term=".c"
fi

#Parsing parameters

while [ $# -gt 0 ]; do
	if [ "$1" == "-l" ]; then
		shift 1
		if [ $# -eq 0 ]; then
			echo "You have not specified any library."
		else
			gcclib="$gcclib ""-l $1"
		fi
	elif [ "$1" == "-a" ]; then
		shift 1
		if [ $# -eq 0 ]; then
			echo "You have not specified any argument."
		fi
		while [ $# -gt 0 ]; do
			my_args="$my_args $1"
			shift 1
		done
		break
	elif [ "$1" == "-vv" ]; then
		valgrind_cmd="valgrind --leak-check=full "
	elif [ "$1" == "-v" ]; then
		valgrind_cmd="valgrind "
	elif [ "$1" == "-r" ]; then
		non_recursive="-maxdepth 1"
	elif [ "$1" == "-k" ]; then
		no_remove=true
	elif [ "$1" == "-c" ]; then
		no_run=true
	elif [ "$1" == "-t" ]; then
		time_cmd="time "
	elif [ "$1" == "-s" ]; then
		err_redir=" 2> /dev/null"
	else
		things="$things"$'\n'"$1"
	fi
	shift 1
done

if [ "$things" == "" ]; then
	things=$PWD
fi

#Searching for files

bkp=$IFS
IFS=$'\n'
for location in $things; do
	if [ ! -d "$location" ] && [ ! -f "$location" ]; then
		echo "$location is not a valid directory or file."
		continue
	fi

	if [ -f "$location" ] && [ $(echo $location | grep -c "\(${term}$\)\|\(.h$\)") -eq 1 ]; then
		files[$position]="\"$location\""
		position=$(($position+1))
		if [ $(grep -c "int main(" "$location") -eq 1 ];then
			mainfile="$(echo "$location" | sed "s/${term}$//")"
		fi
	elif [ -f "$location" ]; then
		echo "$location does not terminate with .cpp"
	fi

	if [ -d "$location" ]; then
		bkp2=$IFS
		IFS=$'\n'
		for source_file in $(eval "find \"$location\" $non_recursive"); do
			if [ -f "$source_file" ] && [ $(echo $source_file | grep -c "\(${term}$\)\|\(.h$\)") -eq 1 ]; then
				files[$position]="\"$source_file\""
				position=$(($position+1))
				if [ $(grep -c "int main(" "$source_file") -eq 1 ];then
					mainfile="$(echo "$source_file" | sed "s/${term}$//")"
				fi
			fi
		done
		IFS=$bkp2
	fi
done
IFS=$bkp

#Compiling and running files found

mainfile=$(readlink -f "$mainfile")

echo "------COMPILING------"
if eval "$compiler -Wall -Wextra -Wshadow -O2 -ggdb3 -D_GLIBCXX_ASSERTIONS -DWATER_ADDICT ${files[@]} -o \"$mainfile\" $gcclib$err_redir"; then
	if ! $no_run; then
		echo "------RUNNING PROGRAM------"
		ulimit -s unlimited
		eval "$time_cmd$valgrind_cmd\"$mainfile\" $my_args"
		if ! $no_remove; then
			rm "$mainfile"
		fi
		echo "------FINISHED------"
	fi
	exit 0
fi
echo "------COMPILATION FAILED------"
exit 1
