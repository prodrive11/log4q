# log4q

log4q is a concise logger for q/kdb+ applications.

It allows you to control the quantity of logging messages very effectively.

You can set up the logging severity level, which will filter messages dynamically.

You can redirect logging messages simultaneously to entirely different outputs: append to a file, send by email etc.

log4q has a simple API and a ready-to-use setup.


## Features summary

* multiple severity levels
* multiple logging levels
* multiple output sinks – STDIN/OUT, FILE, TCP, EMAIL and partial syslog support 
* particular log levels are sent only to chosen sinks, filtered by severity level
* simplified set of pattern layouts available – run-time switchable
* `printf`-like injection of variables 


## Command-line options 

The options and their arguments are… optional.

`-log (debug|info|warn|error|fatal|silent)`
: Sets severity level, only [level] or above will be sent to appropriate sink
: Default severity: `info`


## User functions 

log4q defines six logger functions in the root namespace:
`SILENT`, `DEBUG`, `INFO`, `WARN`, `ERROR` and `FATAL`

Sinks management:

-   `.log4q.a` adds sink
-   `.log4q.r` removes sink

All logic is in the `.l` namespace.
<!-- 
FIXME 
All single-character namespaces are reserved for use by Kx.
http://code.kx.com/q/ref/card/#namespaces
 -->

## Logger functions 

Syntax: `x[y]`

where `x` is one of
`SILENT`, `DEBUG`, `INFO`, `WARN`, `ERROR` and `FATAL`
and `y` is

-   an atom
-   a list
-   (string; atom)
-   (string; list)

The last two forms support `C-printf`-like injection of variables 


### Variable injection in strings

Variables are denoted by their position in the list, escaped with `%`.

For example 
```
("param1: %1, param2: %2";(`one;2))
```
will produce 
```
"param1: `one, param2: 2"
```

#### Examples
```
ERROR "simple message";
INFO (23.;`test);
WARN `test;
SILENT 23;
INFO ("%1 %2";(`Test;2));
```


## Sink functions and log outputs 

A _sink_ is a destination for log messages.

All sinks receive their messages _simultaneously_ i.e. a single message is sent to multiple outputs.

Those can be as follows – but certainly not limited to this list.


### STD out/err

Outputs to stdout and stderr are predefined as follows:
```q
.log4q.a[1;`SILENT`DEBUG`INFO`WARN];
.log4q.a[2;`ERROR`FATAL];
```
Messages from `SILENT`, `DEBUG`, `INFO` and `WARN` go to stdout (1); messages from `WARN`, `ERROR` and `FATAL` go to stderr (2).


### File handle

```q
.log4q.a[hopen `:my_test2.log;`DEBUG`INFO]
```
pushes all `DEBUG` and `INFO` messages to file `./my_test2.log`.


### TCP handle 

```
.log4q.a[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
```
sends updates to the server at localhost:5555 when any messages are sent by `INFO`, `ERROR` or `FATAL`.


### Email 

```
f: {[x;y]
    sub: "log4q message";
    addr: "group@abc.com";
    system "echo \"",y,"\" | mailx -s \"",sub,"\" ",addr;
    };
.log4q.a[(-333;f); `ERROR`FATAL]
```
sends an email to `group@abc.com` when any `ERROR` or `FATAL` message is sent.


### syslog 

```
.log4q.a[(-334;{[x;y] system "logger ",y;});`INFO`ERROR`FATAL];
```
posts a simple syslog message using `logger`. See `man logger` for more advanced features.

If there were a community request for native syslog support, I would contribute a c-syslog-library.

**Watch out**

* low severity messages might go nowhere if you set up high (fatal) or silent severity
* sinks can be added or removed any time; remember you are responsible for managing handles – look out for closing and duplicated handles


## Logger pattern layouts 

A focus on keywords is more natural for q than for Java or Perl logger libraries.

You can define output formats using predefined patterns of the following form: `"%[a-zA-Z]"`.

The default format is
```
.log4q.fm: "%c\t[%p]:H=%h:PID[%i]:%d:%t:%f: %m\r\n"
```


### Supported formats
token | semantics
------|-----------------------------------------------
`%c`  | Category of the logging event
`%d`  | Current date (`.z.d`)
`%t`  | Current time (`.z.t`)
`%f`  | File where the logging event occurred (`.z.f`)
`%h`  | Hostname (`.z.h`)
`%m`  | Message content
`%p`  | Timestamp (`.z.p`)
`%i`  | PID of the current process

**Watch out**
* the format in `.log4q.fm` can be switched in runtime
* supported formats can be changed and extended in the `.log4q.m` dictionary

Runtime format switch example
```q
q)ERROR "simple message";
    ERROR   [2012.03.01D23:32:30.609375000]:PID[1924];log4.q: simple message

q).log4q.fm: "%c\t[%p]:H:%h;PID[%i];%d;%t;%f: %m\r\n"
q)ERROR ("%1 simple message"; `another);
    ERROR   [2012.03.01D23:34:30.234375000]:H:prodrive-notebo;PID[1924];2012.03.01;23:34:30.234;log4.q: `another simple message
```


## Examples 

### Simple app using log4.q
```q
\l log4.q

// adding logging to file on ERROR and FATAL messages
.log4q.a[hopen `:./app_logging.log;`ERROR`FATAL];

foo:{ $[x; INFO ("Param x:%1 correct";x); WARN ("Param x:%1 suspicious";x)];};
.z.exit:{ERROR "App finished";}


INFO "App initialized";

foo[1];
foo[0];
```
The script will produce the following outputs:

#### Severity: info
```bash
q app.q -log info
KDB+ 2.8 2012.02.02 Copyright (C) 1993-2012 Kx Systems
w32/ 1()core 2038MB prodrive11 prodrive-notebo xxx.xx.xx.xx PLAY 2012.05.02

INFO    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: App initialized
INFO    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: Param x:1 correct
WARN    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: Param x:0 suspicious
q)\\
ERROR   [2012.03.03D21:09:52.421875000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:52.421:app.q: App finished
```


#### Severity: warn
```bash
q app.q -log warn
KDB+ 2.8 2012.02.02 Copyright (C) 1993-2012 Kx Systems
w32/ 1()core 2038MB prodrive11 prodrive-notebo xxx.xx.xx.xx PLAY 2012.05.02

WARN    [2012.03.03D21:10:00.234375000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:00.234:app.q: Param x:0 suspicious
q)\\
ERROR   [2012.03.03D21:10:08.703125000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:08.703:app.q: App finished
```
After two such runs file `./app_logging.log` will have the following output. (Note the different PIDs):
```
ERROR	[2012.03.03D21:09:52.421875000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:52.421:app.q: App finished
ERROR	[2012.03.03D21:10:08.703125000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:08.703:app.q: App finished
```


### TCP log messages

```bash
#start process which would like to listen for any logs 
q -p 5555
```
```q
q)upd:{[x;y] 0N!(x;y);}
```

```bash
#start a process which will produce some logs
q log4.q -p 5001 -log info
```
```q
q)INFO ("Test %1 log";1222);
    INFO    [2012.03.01D23:14:17.718750000]:log4.q: Test 1222 log
q)DEBUG ("Test %1 log";1222);
q).log4q.snk
    SILENT| 1
    DEBUG | 1
    INFO  | 1
    WARN  | 1
    ERROR | 2
    FATAL | 2
```
Add TCP sink with function which will send a update message to defined handle
```q
q).log4q.a[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
q).log4q.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | 2 1800
	
q)ERROR ("Test %1 log";1222);
    ERROR   [2012.03.01D23:15:22.609375000]:log4.q: Test 1222 log
```
On our 5555 listener we see that the log was received.
See that log was also printed to stderr on our 5001 process.
```
q)(`msg;"ERROR\t[2012.03.01D23:15:22.609375000]:log4.q: Test 1222 log\r\n")
```


### Adding and removing a sink 

```q
q).log4q.r[1;`DEBUG`INFO] /removes logging to stdout at DEBUG and `INFO severity

q).log4q.a[hopen `:my_test2.log;`INFO`ERROR]
q).log4q.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | ,2

q).log4q.r[1800;`INFO`ERROR]
q).log4q.snk
    SILENT| 1
    DEBUG | 1
    INFO  | 1
    WARN  | 1
    ERROR | 2
    FATAL | 2

q).log4q.a[1800;`INFO`ERROR]
q).log4q.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | ,2
```

