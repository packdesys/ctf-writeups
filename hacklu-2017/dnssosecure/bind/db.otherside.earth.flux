@       IN      SOA     ns1.otherside.earth.flux.       postmaster.domain.tld. (
        2726428884      ; Serial
                1D      ; Refresh
                1H      ; Retry
                1W      ; Expire
                3H )    ; Negative Cache TTL

@               IN      NS      ns1.otherside.earth.flux.
                IN      NS      ns2.otherside.earth.flux.

; Enregistrements A/AAAA

@                   IN                A                    62.210.72.56
ns1			IN 	A 192.168.1.1
ns2			IN 	A 192.168.1.1


$INCLUDE "/etc/bind/Ksecret+007+11537.key" ;
$INCLUDE "/etc/bind/Ksecret+007+26883.key" ;
