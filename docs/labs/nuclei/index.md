# Lab - Nuclei

???+ warning "Start Juice Shop First"
    Start up a the OWASP Juice Shop vulnerable web application. It will be available at `http://127.0.0.1:42000`.

    ```bash
    sudo juice-shop -h
    ```

    After you’re done, make sure you shut down OWASP Juice Shop by running the below command.

    ```bash
    sudo juice-shop-stop -h
    ```

## Intro
Nuclei is used to send requests across targets based on a template, leading to zero false positives and providing fast scanning on a large number of hosts. Nuclei offers scanning for a variety of protocols, including TCP, DNS, HTTP, SSL, File, Whois, Websocket, Headless, Code etc. With powerful and flexible templating, Nuclei can be used to model all kinds of security checks.

## Walkthrough

First, let’s look at the `help` information for Nuclei.

```bash
nuclei -h
```

![image.png](images\image.png)

There’s a LOT in that `help` output, but first and foremost it gives us some options around targeting and templates.

### Templates

???+ note
    All the Nuclei templates should get automatically installed locally at `/home/telchar/nuclei-templates` when you run the tool for the first time. You can also explore them there if you wish. Take a look by running the below command.

    ```bash
    ll ~/nuclei-templates
    ```

First, let’s look at an example template since template are what makes Nuclei awesome. Go to [https://github.com/cstraynor/nuclei-templates/blob/main/http/vulnerabilities/apache/apache-solr-log4j-rce.yaml](https://github.com/cstraynor/nuclei-templates/blob/main/http/vulnerabilities/apache/apache-solr-log4j-rce.yaml) in a browser and you should see the template to detect the Log4J remote code execution vulnerability. 

This vulnerability gained some notoriety in for being particularly wide spread and critical. It was so severe that the Cybersecurity & Infrastructure Security Agency (CISA) issued guidance on it ([https://www.cisa.gov/news-events/news/apache-log4j-vulnerability-guidance](https://www.cisa.gov/news-events/news/apache-log4j-vulnerability-guidance)).

![Template Snippet](images\image%201.png)

Template Snippet

As we can see from the image above, the template provides helpful references and links along with a description of the issue and CVSS scoring.

Further down in the template we see the actual HTTP request and matching rules used to fingerprint the existence of this RCE vuln on a target.

![image.png](images\image%202.png)

### HTTP

Now, let’s take a look at the available templates nuclei uses via the nuclei command itself.. There are thousands. So, we’re going to take a glimpse at just the HTTP ones by running the below command which pipes nuclei’s output to`grep` and filters it.

```bash
nuclei -tl | grep "http/"
```

Taking a look at the output snippet below we can see there is a good variety of checks related to HTTP. Including specific CVEs, OSINT, known vulnerabilities, and more.

![HTTP Templates (Snippet)](images\image%203.png)

HTTP Templates (Snippet)

Since we have a local vulnerable web application already running on The Forge VM, let’s go ahead and run nuclei with OWASP juice shop as the target. No additional options.

```bash
nuclei -target 127.0.0.1:42000
```

- `-target 127.0.0.1:42000`: [using -u also works for specifying a target] Specifies the **target** for scanning, which in this case is the local machine (`127.0.0.1`) on port `42000`. That’s where OWASP juice shop is running.

![Basic Command Output](images\image%204.png)
///caption
Basic Command Output
///

Already we can see that Nuclei does a fairly good job at the basics without any additional configuration. Now, if you had a large list of systems you could use the `-l` option and provide the path to a file containing a list of target URLs/hosts to scan (one per line).

Lets try one more target. This time it’ll be Portswigger’s `ginandjuice.shop` website, which is “a deliberately vulnerable web application designed for testing web vulnerability scanners”.

```bash
nuclei -target [https://ginandjuice.shop](https://ginandjuice.shop/)
```

This will produce more broad results as it is a proper deployed web application on the open internet.

![ginandjuice.shop](images\image%205.png)
///caption
ginandjuice.shop
///

Since this target has encryption enabled, we see which versions of TLS is supported. We also see whois lookup details and nuclei detected this web application is hosted in AWS.

### Network

Nuclei isn’t just for HTTP and web apps. It also has a LOT of network focused templates. Let’s re-run that same template listing command but this time we’ll filter in “network” and take a look.

```bash
nuclei -tl | grep "network/"
```

![Network Templates (Snippet)](images\image%206.png)
///caption
Network Templates (Snippet)
///

???+ warning
    You’ll need GOAD-SRV02 running for this next part.

Let’s see what happens if we point Nuclei at one of our GOAD target servers.

```bash
nuclei -target 192.168.56.22
```

We can see in the screenshot below that Nuclei detected MSSQL, SMB, and IIS running on the target. Also, it did additional checks when there were applicable templates after a service was detected.

![Network Scanning (Snippet)](images\image%207.png)
///caption
Network Scanning (Snippet)
///

Note how we didn’t tell Nuclei that we wanted to use network related templates instead of HTTP ones. It figures that out on its own.

## Create Your Own Template

Watch the incomparable BB King’s Nuclei webcast ([https://www.youtube.com/watch?v=oajbdFOnVEY&t=2522s](https://www.youtube.com/watch?v=oajbdFOnVEY&t=2522s)) and attempt to create your own Nuclei template for Apache’s server status.

???+ note
    If web apps are your thing, then I highly recommend BB’s classes ([https://www.antisyphontraining.com/instructor/bb-king/](https://www.antisyphontraining.com/instructor/bb-king/)).

…OR…

Try creating a template on your own for something network related which targets our Lab VMs.