import requests

hosts = []
with open("cd3.txt") as f:
    hosts = f.readlines()
    f.close()

#hosts = hosts[:50]

htimeout = []
hrefused = []
hbadcert = []
hinchain = []
hredirect = []
hsslerror = []
hsslisok = []
rules = []

# Check for SSL availability
for host in hosts:
    host = host.rstrip()
    print("+" + host)
    try:
        res = requests.head("https://" + host + "/", timeout=10, allow_redirects=True)
        print(res.status_code)
        if res.url.startswith("https"): # Check if redirected to HTTP
            if res.url.startswith("https://" + host + "/"):
                hsslisok.append(host)
            else:
                rules.append([host, res.url])
        else:
            hredirect.append(host)
    except requests.exceptions.SSLError as err:
        msg = str(err)
        if "doesn't match" in msg:
            hbadcert.append(host)
        elif "CERTIFICATE_VERIFY_FAILED" in msg:
            hinchain.append(host)
        else:
            hsslerror.append(host)
    except requests.exceptions.Timeout:
        htimeout.append(host)
    except requests.exceptions.RequestException:
        hrefused.append(host)


hsuccess = []
hdiffcont = []

# Check for different content
def diffcontentcheck(host, httpcode, httpcont):
    "This function checks if the HTTP and HTTPS version have different content or not"
    res = requests.get("https://" + host + "/", timeout=10)
    if res.status_code//100 != 2: # 4xx/5xx must be diff content
        hdiffcont.append(host)
        return
    
    if httpcode //100 != 2 and res.status_code//100 == 2:
        hsuccess.append(host)
        
    if abs(len(res.content) - len(httpcont)) < 50: # TODO: Update this
        hsuccess.append(host)
    else:
        hdiffcont.append(host)

for host in hsslisok:
    print("-" + host)
    res = requests.get("http://" + host + "/", timeout=10, allow_redirects=True)
    if res.history:
        if res.url.startswith("https"):
            hsuccess.append(host) # Redirects to HTTPS so cannot be different content
        else:
            diffcontentcheck(host, res.status_code, res.content)
    else:
        diffcontentcheck(host, res.status_code, res.content)


f = open('europa.eu.xml', 'w')
f.write("<!--\n")
f.write("\n")
f.write("   Refused:\n")
for host in hrefused:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Timeout:\n")
for host in htimeout:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Wrong certificate:\n")
for host in hbadcert:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Incomplete certificate-chain:\n")
for host in hinchain:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Other unknown SSL error:\n")
for host in hsslerror:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Redirects to HTTP:\n")
for host in hredirect:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("   Different content:\n")
for host in hdiffcont:
    f.write("       - " + host + "\n")
f.write("\n")
f.write("-->\n")

f.write("<ruleset name=\"European Union\">\n")
f.write("\n")
for host in hsuccess:
    f.write("   <target host=\"" + host + "\" />\n")
f.write("\n")
f.write("   <securecookie host=\".+\" name=\".+\" />\n")
f.write("\n")
for r in rules:
    f.write("   <target from=\"^http://" + r[0].replace(".", "\\.") + "/\"\n to=\"" + r[1] + "\"/>\n")
f.write("\n")
f.write("   <rule from=\"^http:\" to=\"https:\" />\n")
f.write("</ruleset>\n")