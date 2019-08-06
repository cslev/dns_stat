#!/bin/bash

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
  c_print bold "\t./dns_stat.sh [filename_of_domains] [only_one_ns_at_a_time] [output]"
  c_print none "\t-> filename_of_domains: list of domains each in a separate line in the file"
  c_print none "\t-> only_one_ns_at_a_time: 0/1 (there can be even more than 200 nameservers for a domain which clearly lengthens the running time) - 1 means only one NS, 0 means all of them"
  c_print none "\t-> output: the output filename where the results will be saved"
  exit -1
}

function calculate_rtt ()
{
  ip=$1
  res=$(ping $ip -c 3 -q |grep "avg"|cut -d '=' -f 2|sed 's/ //g'|cut -d '/' -f 2)
  return $res
}

if [ $# -ne 3 ]
then
  print_help
fi


filename=$1
only_one_ns=$2
output=$3

if [ $only_one_ns -ne 0 ] && [ $only_one_ns -ne 1 ]
then
  print_help
fi

output="${output}.csv"

c_print bold "Analysing $filename for domains:"
c_print bold "\tOnly one ns = $only_one_ns"
c_print bold "\tOutput file will be: ${output}"


echo "ID,IP,NAMESERVER,Ping RTT,Query time,Msg size" > $output


ID=1

for domain_name in $(cat $filename|cut -d ',' -f 2)
do
  cmd="dig $domain_name NS |grep NS|grep -v ';'| sed 's/[[:blank:]]/;/g'|cut -d ';' -f 6"
  # if we don't care about all nameservers, we simply add head -n1 to the command
  c_print blue "Checking ${domain_name}..."
  sleep 1
  #go through the NS records only and filter out AAAA (IPv6 records) and get the
  #nameserver's domain name and its corresponding IP address (hence awk $1, $5)
  # echo $cmd
  for i in $(dig $domain_name NS |grep NS|grep -v ';'| sed 's/[[:blank:]]/;/g'|cut -d ';' -f 6)
    do
      # echo $i
      #there is a dot (.) at the end of the nameserver...get rid of that
      ns=$(echo "${i%?}")

      # get the IP address assigned to the DNS
      ip=$(nslookup $ns |grep Address|tail -n1|cut -d ':' -f 2|sed 's/ //g')

      #print out intermediate information
      c_print yellow "Querying ${ns} (at ${ip}) for the ANY records of ${ns} itself!"
      # echo "dig @$ip $ns ANY +tries=1 +time=2|tail -n 5 > tmp_${ns}"
      dig @$ip $ns ANY +tries=1 +time=2|tail -n 5 > tmp_${ns}
      query_time=$(cat tmp_${ns}| grep -i "Query time"| cut -d ':' -f 2|sed 's/ //g')
      msg_size=$(cat tmp_${ns}| grep -i "MSG SIZE"| cut -d ':' -f 2|sed 's/ //g')

      ping_rtt=$(ping $ip -c 3 -q |grep "avg"|cut -d '=' -f 2|sed 's/ //g'|cut -d '/' -f 2)

      echo "${ID},${ip},${ns},${ping_rtt},${query_time},${msg_size}" >> $output
      rm -rf tmp_${ns}
      ID=`expr $ID + 1`

      #we break the loop if only the first NS should have been considered only
      if [ $only_one_ns -eq 1 ]
      then
        break
       #there was no other solution for this! Adding |head -n1 to the command
       #seems a good idea but then the comman should be stored as a variable.
       #which is cumbersome to execute efficiently (e.g., via $($command) does
       #not work all the time)
      fi
    done
done
