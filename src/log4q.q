\d .l
fm:"%c\t[%p]:H=%h:PID[%i]:%d:%t:%f: %m\r\n";
sev:snk:`SILENT`DEBUG`INFO`WARN`ERROR`FATAL!();a:{$[1<count x;[h[x 0]::x 1;snk[y],::x 0];[h[x]::{x@y};snk[y],::x;]];};r:{snk::@[snk;y;except;x];};
h:m:()!();m["c"]:{[x;y]string x};m["f"]:{[x;y]string .z.f};m["p"]:{[x;y]string .z.p};m["m"]:{[x;y]y};m["h"]:{[x;y]string .z.h};m["i"]:{[x;y]string .z.i};m["d"]:{[x;y]string .z.d};m["t"]:{[x;y]string .z.t};
l:{ssr/[fm;"%",/:lfm;m[lfm:raze -1_/:2_/:nl where fm like/: nl:"*%",/:(.Q.a,.Q.A),\:"*"].\:(x;y)]};
p:{$[10h~type x:(),x;x;(2~count x) & 10h~type x 0;ssr/[x 0;"%",/:string 1+til count (),x 1;.Q.s1 each (),x 1];.Q.s1 x]};
sevl:$[`log in key .Q.opt .z.x;first `$upper first .Q.opt .z.x;`INFO];
(` sv' ``l,/:`$(),/:each[first;string lower key snk]) set' {{@[.l.h[x]x;y;{[h;e]'"log4q - ", string[h]," exception:",e}[x]]}[;l[x] p y]@/:snk[x]}@/: key[snk];n:(::);
sev:key[snk]!((n;n;n;n;n;n);(n;d;i;w;e;f);(n;n;i;w;e;f);(n;n;n;w;e;f);(n;n;n;n;e;f);(n;n;n;n;n;f));
a[1;`SILENT`DEBUG`INFO`WARN];a[2;`ERROR`FATAL]; 
\d .
key[.l.snk] set' .l.sev .l.sevl;




/
========================
log4q alike 
	p.bukowinski@gmail.com
=========================
Features:
	* various severity levels
	* various logging levels
	* various sinks - STDIN/OUT, FILE, TCP
	* particular levels logs sent only to choosen sinks, all filtered by severity level
	* simplified set of pattern layouts available - runtime switchable
	* pre-log "printf" alike variables injecting

---------------
commandline opts:
---------------
	sets severity
	-log [(silent|debug|info|warn|error|fatal)]
	default severity: info

---------------
log examples:
---------------
ERROR "simple message";
INFO (23.;`test);
WARN `test;
SILLENT 23;

/printf alike formatting:
q)INFO ("This is a log %1 %2 %3";(23;`adf;(3;{x+y});4));
INFO    [2012.03.01D23:44:01.593750000]:log4.q: This is a log 23 `adf (3;{x+y})


---------------
default sinks:
---------------
(silent, debug, info and warn) to stdout
(warn, error and fatal) to stderr

---------------
Logs pattern layout - format (.l.fm) 
---------------
* can be changed in runtime
supported formats:

	%c Category of the logging event.
    %d Current date  (.z.d)
	%t Current time (.z.t)
    %f File where the logging event occurred (.z.f)
    %h Hostname (.z.h)
    %m The message to be logged
    %p Timestamp (.z.p)
    %i pid of the current process

ex.
q)ERROR "simple message";
ERROR   [2012.03.01D23:32:30.609375000]:PID[1924];log4.q: simple message
q).l.fm:"%c\t[%p]:H:%h;PID[%i];%d;%t;%f: %m\r\n"
q)ERROR ("%2 simple message";`another);
ERROR   [2012.03.01D23:34:30.234375000]:H:prodrive-notebo;PID[1924];2012.03.01;23:34:30.234;log4.q: %2 simple message


---------------
sinks management
---------------
* user manages handles on his own

/add sink  
* file handle
	.l.a[hopen `:my_test2.log;`INFO`ERROR]
* TCP handle with special modification function
	.l.a[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
  
ex:
	q -p 5555
	-----------
	q)upd:{[x;y] 0N!(x;y);}

	q log4.q -p 5001 -log info
	-----------
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
	
	proc (5555)
	-----------
	q)(`msg;"ERROR\t[2012.03.01D23:15:22.609375000]:log4.q: Test 1222 log\r\n")

/remove sink
	.l.r[1;`DEBUG`INFO] /removes logging to stdout at DEBUG and `INFO severity

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
