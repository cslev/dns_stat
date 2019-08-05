# dns_stat
Script for generating DNS statistics

# detailed description
This application is intended to go through a list of top domain names, ask for
their representative DNS servers and then query those DNS servers with their
exact domain to get a response.
The responses are then gathered with their response time and package size when
ANY was added to the DNS query

# Usage
./dns_stat [list_of_domains]
