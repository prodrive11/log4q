= Outline =
[http://code.kx.com/wsvn/code/contrib/pkbukowi/log4q/log4.q log4q] is a concise implementation of logger for q/kdb+ applications.<br>
It allows you to control the amount of logging messages generated very effectively.<br>
You can setup the logging severity level which will filter out messages dynamically.<br>
You can redirect logging messages to an entirely different outputs (append to a file, send by email etc.) simultaneously.
log4q Provides simple api and ready to use setup.<br>


;Features summary
* various severity levels
* various logging levels
* various output sinks - STDIN/OUT, FILE, TCP, EMAIL and partial syslog support 
* particular log levels are sent only to chosen sinks, filtered by severity level
* simplified set of pattern layouts available - run-time switchable
* ''printf'' alike variables injecting


= Command line options =
Options are not mandatory, options arguments are mandatory.

;-log (debug|info|warn|error|fatal|silent)
:sets severity level, only [level] or above will be sent to appropriate sink
:default severity: info


= User functions =
;log4g defines six logger functions in global namespace
:SILENT DEBUG INFO WARN ERROR or FATAL
;sinks management
:.l.a - adds sink
:.l.r - removes sink

{{admon/note|All logic is placed in '''.l''' namespace.}}

== Logger functions ==

;synopsis
:LOG_FUNCTION + PARAM
possible parameters
:*atom
:*list
:*(string;atom)  
:*(string;list)

Last two parameter layouts supports ''C-printf'' alike variable injecting 
;Format keywords 
:<pre>"(%[1-9])+"</pre>
:<pre>("param1: %1, param2: %2";(`one;2)) will produce ==> "param1: `one, param2: 2"</pre>

;examples
<pre>
ERROR "simple message";
INFO (23.;`test);
WARN `test;
SILENT 23;
INFO ("%1 %2";(`Test;2));
</pre>


== Sink functions - log outputs ==
Sink is generic name for log message output.<br>
All defined sinks will receive their messages ''simultaneously'' - means one message sent to various outputs.<br>
Those can be as follows, but certainly not limited to this list;
=== STD out/err ===
Stdout and stderr are predefined out of the box as follows:
:<pre>a[1;`SILENT`DEBUG`INFO`WARN];a[2;`ERROR`FATAL];</pre>
:messages ''silent, debug, info and warn'' will be sent to stdout (1)
:''warn, error and fatal'' will be sent to stderr (2)
=== File handle ===
:<pre>.l.a[hopen `:my_test2.log;`DEBUG`INFO]</pre>
:will push all DEBUG and INFO messages to ''./my_test2.log'' file
=== TCP handle ===
:<pre>.l.a[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]</pre>
:above will send updates to server 5555@localhost when any of INFO,ERROR or FATAL message will occur.
=== Email ===
:<pre>.l.a[(-333;{[x;y]sub:"log4q message";addr:"group@abc.com";system "echo \"",y,"\" | mailx -s \"",sub,"\" ",addr;});`ERROR`FATAL]</pre>
:this will send email to ''group@abc.com'' when any ERROR or FATAL message will happen
=== syslog ===
:<pre>.l.a[(-334;{[x;y] system "logger ",y;});`INFO`ERROR`FATAL];</pre>
:simple syslog message post using ''logger'' app, please check ''man logger'' for more advanced features
:if there will be a community request for native syslog support, I can contribute a c-syslog-library.
{{admon/note| '''Reminder'''
* low severity messages might not be sent anywhere, if you'll set up high (fatal) or silent severity
* sinks can be added or removed any time, but remember about below:
* user is responsible for handles management, so be aware of handle duplicates and closing
}}


= Logger pattern layouts =
log4q focus on keywords more natural for q than for java or perl logger libraries.<br>
User can define output format using predefined patterns which is of following format:
<pre>"%[a-zA-Z]"</pre>

default format 
<pre>.l.fm:"%c\t[%p]:H=%h:PID[%i]:%d:%t:%f: %m\r\n"</pre>


'''Supported formats:'''
----
<pre>
    %c Category of the logging event.
    %d Current date  (.z.d)
    %t Current time (.z.t)
    %f File where the logging event occurred (.z.f)
    %h Hostname (.z.h)
    %m The message to be logged
    %p Timestamp (.z.p)
    %i pid of the current process
</pre>


{{admon/note| '''Reminder'''
* format in '''.l.fm''' can be switched in run-time
* supported formats can be changed and extended in '''.l.m''' dictionary
}}



Example runtime format switch
<pre>
q)ERROR "simple message";
    ERROR   [2012.03.01D23:32:30.609375000]:PID[1924];log4.q: simple message

q).l.fm:"%c\t[%p]:H:%h;PID[%i];%d;%t;%f: %m\r\n"
q)ERROR ("%1 simple message";`another);
    ERROR   [2012.03.01D23:34:30.234375000]:H:prodrive-notebo;PID[1924];2012.03.01;23:34:30.234;log4.q: `another simple message
</pre>



= Examples =

== Simple app utilizing log4.q ==
<pre>
\l log4.q

// adding logging to file on ERROR and FATAL messages
.l.a[hopen `:./app_logging.log;`ERROR`FATAL];

foo:{ $[x; INFO ("Param x:%1 correct";x); WARN ("Param x:%1 suspicious";x)];}
.z.exit:{ERROR "App finished";}


INFO "App initialized";

foo[1];
foo[0];

</pre>


It will produce following outputs<br>
severity - '''info'''
<pre>
q app.q -log info
KDB+ 2.8 2012.02.02 Copyright (C) 1993-2012 Kx Systems
w32/ 1()core 2038MB prodrive11 prodrive-notebo xxx.xx.xx.xx PLAY 2012.05.02

INFO    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: App initialized
INFO    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: Param x:1 correct
WARN    [2012.03.03D21:09:51.109375000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:51.109:app.q: Param x:0 suspicious
q)\\
ERROR   [2012.03.03D21:09:52.421875000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:52.421:app.q: App finished

</pre>


severity - '''warn'''
<pre>
q app.q -log warn
KDB+ 2.8 2012.02.02 Copyright (C) 1993-2012 Kx Systems
w32/ 1()core 2038MB prodrive11 prodrive-notebo xxx.xx.xx.xx PLAY 2012.05.02

WARN    [2012.03.03D21:10:00.234375000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:00.234:app.q: Param x:0 suspicious
q)\\
ERROR   [2012.03.03D21:10:08.703125000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:08.703:app.q: App finished

</pre>


After two above runs file '''./app_logging.log''' will have following output (pay attention to different PIDs):
<pre>
ERROR	[2012.03.03D21:09:52.421875000]:H=prodrive-notebo:PID[3460]:2012.03.03:21:09:52.421:app.q: App finished
ERROR	[2012.03.03D21:10:08.703125000]:H=prodrive-notebo:PID[4000]:2012.03.03:21:10:08.703:app.q: App finished
</pre>



== TCP log messages ==
<pre>
#start process which would like to listen for any logs 
q -p 5555

q)upd:{[x;y] 0N!(x;y);}
</pre>

<pre>
#start a process which will produce some logs
q log4.q -p 5001 -log info

q)INFO ("Test %1 log";1222);
    INFO    [2012.03.01D23:14:17.718750000]:log4.q: Test 1222 log
q)DEBUG ("Test %1 log";1222);
q).l.snk
    SILENT| 1
    DEBUG | 1
    INFO  | 1
    WARN  | 1
    ERROR | 2
    FATAL | 2
</pre>


Add TCP sink with function which will send a update message to defined handle
<pre>
q).l.a[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
q).l.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | 2 1800
	
q)ERROR ("Test %1 log";1222);
    ERROR   [2012.03.01D23:15:22.609375000]:log4.q: Test 1222 log
</pre>


On our 5555 listener we see that the log was received.
See that log was also printed to stderr on our 5001 process.
<pre>
q)(`msg;"ERROR\t[2012.03.01D23:15:22.609375000]:log4.q: Test 1222 log\r\n")
</pre>

== Adding and removing sink ==
<pre>
q).l.r[1;`DEBUG`INFO] /removes logging to stdout at DEBUG and `INFO severity

q).l.a[hopen `:my_test2.log;`INFO`ERROR]
q).l.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | ,2

q).l.r[1800;`INFO`ERROR]
q).l.snk
    SILENT| 1
    DEBUG | 1
    INFO  | 1
    WARN  | 1
    ERROR | 2
    FATAL | 2

q).l.a[1800;`INFO`ERROR]
q).l.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | ,2
</pre>



= Reporting bugs =

Report bugs to [mailto:p.bukowinski@gmail.com patryk]
