#!/bin/bash

# This helper script makes the dns_stat.sh multithreaded.
# it simply cut the input file into pieces (driven by an input parameter)
# and runs the main application with the smaller pieces in parallel

source colorized_output.sh

function print_help ()
{
  c_print red "Unsuffiecent number or format of arguments!"
  c_print yellow "Usage:"
  c_print bold "\t./multi_threaded_dns_stat.sh [filename_of_domains] [only_one_ns] [output] [#threads]"
  c_print none "\t-> filename_of_domains: list of domains each in a separate line in the file"
  c_print none "\t-> only_one_ns: 0/1 (there can be even more than 200 nameservers for a domain which clearly lengthens the running time) - 1 means only one NS, 0 means all of them"
  c_print none "\t-> output: the output filename where the results will be saved - multiple files according to the #threads"
  exit -1
}


if [ $# -ne 4 ]
then
  print_help
fi


filename=$1
only_one_ns=$2
output=$3
threads=$4

if [ $only_one_ns -ne 0 ] && [ $only_one_ns -ne 1 ]
then
  print_help
fi


number_of_all_domains=$(cat $filename |wc -l)
number_of_one_set_of_domains=$(echo "$number_of_all_domains / $threads"|bc)
echo $number_of_one_set_of_domains

c_print green "Cutting the input file into ${threads} pieces"

rm -rf ${filename}_tmp_*
head -n $number_of_one_set_of_domains $filename > "${filename}_for_thread_1"
for i in $(seq 2 $threads)
do
  tmp_num=$(echo "$number_of_one_set_of_domains * $i"|bc)
  head -n $tmp_num $filename|tail -n $number_of_one_set_of_domains > "${filename}_for_thread_${i}"
done

rm -rf ${output}*

for i in $(seq 1 $threads)
do
  ./dns_stat.sh "${filename}_for_thread_${i}" $only_one_ns "${output}_${i}" 2>&1 &
#  echo "${i}" &
done
