#!/usr/bin/env bash

source colorized_output.sh

# this application is intended to go through a list of top domain names, ask for
# their representative DNS servers and then query those DNS servers with their
# exact domain to get a response.
# The responses are then gathered with their response time and package size when
# ANY was added to the DNS query

function print_help ()
{
  c_print red "Unsuffiecent number or format of arguments!"
  c_print yellow "Usage:"
  c_print bold "\t./dns_stat.sh [filename_of_domains] [one_or_more_ns_at_a_time] [output]"
  c_print none "\t\tfilename_of_domains: list of domains each in a separate line in the file"
  c_print none "\t\tone_or_more_ns_at_a_time: 0/1 (there can be even more than 200 nameservers for a domain which clearly lengthens the running time)"
  c_print none "\t\toutput: the output filename where the results will be saved"
  exit -1
}

if [ $# -ne 3 ]
then
  print_help
fi


filename=$1
only_one_ns=$2
output=$3

if [ $only_one_ns -ne 0 ] || [ $only_one_ns -ne 1 ]
then
  print_help
fi

if [ $only_one_ns -eq 0 ]
then
  cmd = "dig $domain_name NS +tries=1 +time=2 |grep -v "AAAA"|grep A|grep -v ";"|awk '{print $1 "-" $5}'"
else
  cmd = "dig $domain_name NS +tries=1 +time=2 |grep -v "AAAA"|grep A|grep -v ";"|head -n1| awk '{print $1 "-" $5}'"
fi

c_print bold "Analysing $filename for domains:"
c_print bold "\tOnly one ns = $only_one_ns"
c_print bold "\tOutput file will be: ${output}"

echo "IP,NAMESERVER,Query time,Msg size" > $output


for domain_name in $(cat $filename|cut -d ',' -f 2)
do
  c_print blue "Checking ${domain_name}..."
  sleep 1
  #go through the NS records only and filter out AAAA (IPv6 records) and get the
  #nameserver's domain name and its corresponding IP address (hence awk $1, $5)
  for i in $($cmd)
  do
    #get the nameserver
    ns=$(echo $i|cut -d '-' -f 1)
    #there is a dot (.) at the end of it...get rid of that
    ns=$(echo "${ns%?}")
    # get the IP address assigned to the DNS
    ip=$(echo $i|cut -d '-' -f 2)

    #print out intermediate information
    c_print yellow "Querying ${ns} (at ${ip}) for the ANY records of ${ns} itself!"
    dig @$ip $ns ANY +tries=1 +time=2|tail -n 5 > tmp_${ns}
    query_time=$(cat tmp_${ns}| grep -i "Query time"| cut -d ':' -f 2|sed 's/ //g')
    msg_size=$(cat tmp_${ns}| grep -i "MSG SIZE"| cut -d ':' -f 2|sed 's/ //g')

    echo "${ip},${ns},${query_time},${msg_size}" >> dns_stats.csv
    rm -rf tmp_${ns}
  done
done
