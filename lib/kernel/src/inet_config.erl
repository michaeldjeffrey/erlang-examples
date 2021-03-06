%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1997-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%
-module(inet_config).

-include("inet_config.hrl").
-include("inet.hrl").

-import(lists, [foreach/2, member/2, reverse/1]).

-export([init/0]).

-export([do_load_resolv/2]).

%%
%% Must be called after inet_db:start
%%
%% Order in which to load inet_db data:
%% 1. Hostname  (possibly derive domain and search)
%% 2. OS default  /etc/resolv.conf,  Windows registry etc
%%    a) Hosts database
%%    b) Resolver options 
%% 3. Config (kernel app)
%% 4. Root   (otp root)
%% 5. Home   (user inetrc)
%%
%%
init() ->
    OsType = os:type(),
    case OsType of
	{ose,_} ->
	    case init:get_argument(loader) of
		{ok,[["ose_inet"]]} ->			
		    %% port already started by prim_loader
		    ok;
		_Other ->
		    %% Setup reserved port for ose_inet driver (only OSE)
		    case catch erlang:open_port({spawn,ose_inet}, [binary]) of
			{'EXIT',Why} ->
			    error("can't open port for ose_inet: ~p", [Why]);
			OseInetPort ->
			    erlang:display({ose_inet_port,OseInetPort})
		    end
	    end;
	_ ->
	    ok
    end,

    set_hostname(),

    %% Note: In shortnames (or non-distributed) mode we don't need to know
    %% our own domain name. In longnames mode we do and we can't rely on 
    %% the user to provide it (by means of inetrc), so we need to look 
    %% for it ourselves.

    do_load_resolv(OsType, erl_dist_mode()),

    case OsType of
	{unix,Type} ->
	    if Type =:= linux ->
		    %% It may be the case that the domain name was not set
		    %% because the hostname was short. But NOW we can look it
		    %% up and get the long name and the domain name from it.
		    
		    %% FIXME: The second call to set_hostname will insert
		    %% a duplicate entry in the search list.
		    
		    case inet_db:res_option(domain) of
			"" ->
			    case inet:gethostbyname(inet_db:gethostname()) of
				{ok,#hostent{h_name = []}} ->
				    ok;
				{ok,#hostent{h_name = HostName}} ->
				    set_hostname({ok,HostName});
				_ ->
				    ok
			    end;
			_ ->
			    ok
		    end;
	       true -> ok
	    end,    
	    add_dns_lookup(inet_db:res_option(lookup));
	_ ->
	    ok
    end,

    %% Read inetrc file, if it exists.
    {RcFile,CfgFiles,CfgList} = read_rc(),

    %% Possibly read config files or system registry
    lists:foreach(fun({file,hosts,File}) ->
			  load_hosts(File, unix);
		     ({file,Func,File}) ->
			  load_resolv(File, Func);
		     ({registry,win32}) ->
			  case OsType of
			      {win32,WinType} ->
				  win32_load_from_registry(WinType);
			      _ ->
				  error("can not read win32 system registry~n", [])
			  end
		  end, CfgFiles),

    %% Add inetrc config entries
    case inet_db:add_rc_list(CfgList) of
	ok -> ok;
	_  -> error("syntax error in ~s~n", [RcFile])
    end,

    %% Now test if we can lookup our own hostname.
    standalone_host().

erl_dist_mode() ->
    case init:get_argument(sname) of
	{ok,[[_SName]]} -> shortnames;
	_ ->
	    case init:get_argument(name) of
		{ok,[[_Name]]} -> longnames;
		_ -> nonames
	    end
    end.

do_load_resolv({unix,Type}, longnames) ->
    %% The Etc variable enables us to run tests with other 
    %% configuration files than the normal ones 
    Etc = case os:getenv("ERL_INET_ETC_DIR") of
	      false -> ?DEFAULT_ETC;
	      _EtcDir -> 
		  _EtcDir				 
	  end,
    load_resolv(filename:join(Etc,"resolv.conf"), resolv),
    case Type of
	freebsd ->	    %% we may have to check version (2.2.2)
	    load_resolv(filename:join(Etc,"host.conf"), host_conf_freebsd);
	'bsd/os' ->
	    load_resolv(filename:join(Etc,"irs.conf"), host_conf_bsdos);
	sunos ->
	    case os:version() of
		{Major,_,_} when Major >= 5 ->
		    load_resolv(filename:join(Etc,"nsswitch.conf"), 
				nsswitch_conf);
		_ -> 
		    ok
	    end;
	netbsd ->
	    case os:version() of
		{Major,Minor,_} when Major >= 1, Minor >= 4 ->
		    load_resolv(filename:join(Etc,"nsswitch.conf"), 
				nsswitch_conf);
		_ ->
		    ok
	    end;		
	linux ->
	    case load_resolv(filename:join(Etc,"host.conf"),
			     host_conf_linux) of
		ok ->
		    ok;
		_ ->
		    load_resolv(filename:join(Etc,"nsswitch.conf"), 
				nsswitch_conf)
	    end;
	_ ->
	    ok
    end,
    inet_db:set_lookup([native]);

do_load_resolv({win32,Type}, longnames) ->	
    win32_load_from_registry(Type),
    inet_db:set_lookup([native]);

do_load_resolv(vxworks, _) ->	
    vxworks_load_hosts(),
    inet_db:set_lookup([file, dns]),
    case os:getenv("ERLRESCONF") of
	false ->
	    no_ERLRESCONF;
	Resolv ->
	    load_resolv(Resolv, resolv)
    end;

do_load_resolv({ose,_Type}, _) ->
    inet_db:set_lookup([file, dns]),
    case os:getenv("NAMESERVER") of
	false ->
	    case os:getenv("RESOLVFILE") of
		false ->
		    erlang:display('Warning: No NAMESERVER or RESOLVFILE specified!'),
		    no_resolv;
		Resolv ->
		    load_resolv(Resolv, resolv)
	    end;
	Ns ->
	    {ok,IP} = inet_parse:address(Ns),
	    inet_db:add_rc_list([{nameserver,IP}])
    end,
    case os:getenv("DOMAIN") of
	false ->
	    no_domain;
	D ->
	    ok = inet_db:add_rc_list([{domain,D}])
    end,
    case os:getenv("HOSTSFILE") of
	false ->
	    erlang:display('Warning: No HOSTSFILE specified!'),
	    no_hosts_file;
	File ->
	    load_hosts(File, ose)
    end;

do_load_resolv(_, _) ->
    inet_db:set_lookup([native]).

%% This host seems to be standalone.  Add a shortcut to enable us to
%% lookup our own hostname.
standalone_host() ->
    Name = inet_db:gethostname(),
    case inet:gethostbyname(Name) of
	{ok, #hostent{}} ->
	    ok;
	_ -> 
	    case inet_db:res_option(domain) of
		"" ->
		    inet_db:add_host({127,0,0,1}, [Name]);
		Domain ->
		    FQName = lists:append([inet_db:gethostname(),
					    ".", Domain]),
		    case inet:gethostbyname(FQName) of
			{ok, #hostent{
			   h_name      = N,
			   h_addr_list = [IP|_],
			   h_aliases   = As}} ->
			    inet_db:add_host(IP, [N | As] ++ [Name]);
			_ ->
			    inet_db:add_host({127,0,0,1}, [Name])
		    end
	    end,
	    Lookup = inet_db:res_option(lookup),
	    case lists:member(file, Lookup) of
		true -> 
		    ok;
		false -> 
		    inet_db:set_lookup(Lookup++[file]),
		    ok
	    end
    end.


add_dns_lookup(L) ->
    case lists:member(dns,L) of
	true -> ok;
	_ ->
	    case application:get_env(kernel,inet_dns_when_nis) of
		{ok,true} -> 
		    add_dns_lookup(L,[]);
		_ ->
		    ok
	    end
    end.

add_dns_lookup([yp|T],Acc) ->
    add_dns_lookup(T,[yp,dns|Acc]);
add_dns_lookup([H|T],Acc) ->
    add_dns_lookup(T,[H|Acc]);
add_dns_lookup([],Acc) ->
    inet_db:set_lookup(reverse(Acc)).

%%
%% Set the hostname (SHORT)
%% If hostname is long use the suffix as default domain
%% and initalize the search option with the parts of domain
%%
set_hostname() ->
    case inet_udp:open(0,[]) of
	{ok,U} ->
	    Res = inet:gethostname(U),
	    inet_udp:close(U),
	    set_hostname(Res);
	_ ->
	    set_hostname({ok, []})
    end.

set_hostname({ok,Name}) when length(Name) > 0 ->
    {Host, Domain} = lists:splitwith(fun($.) -> false;
					(_)  -> true
				     end, Name),
    inet_db:set_hostname(Host),
    set_search_dom(Domain);
set_hostname({ok,[]}) ->
    inet_db:set_hostname("nohost"),
    set_search_dom("nodomain").

set_search_dom([$.|Domain]) ->
    %% leading . not removed by dropwhile above.
    inet_db:set_domain(Domain),
    inet_db:ins_search(Domain),
    ok;
set_search_dom([]) ->
    ok;
set_search_dom(Domain) ->
    inet_db:set_domain(Domain),
    inet_db:ins_search(Domain),
    ok.

%%
%% Load resolver data
%%
load_resolv(File, Func) ->
    case get_file(File) of
	{ok,Bin} ->
            case inet_parse:Func(File, {chars, Bin}) of
		{ok, Ls} ->
		    inet_db:add_rc_list(Ls);
		{error, Reason} ->
		    error("parse error in file ~s: ~p", [File, Reason])
	    end;
	Error ->
	    warning("file not found ~s: ~p~n", [File, Error])
    end.

%%
%% Load a UNIX hosts file
%%
load_hosts(File,Os) ->
    case get_file(File) of
	{ok,Bin} ->
	    case inet_parse:hosts(File,{chars,Bin}) of
		{ok, Ls} ->
		    foreach(
		      fun({IP, Name, Aliases}) -> 
			      inet_db:add_host(IP, [Name|Aliases]) end,
		      Ls);
		{error, Reason} ->
		    error("parse error in file ~s: ~p", [File, Reason])
	    end;
	Error ->
	    case Os of
		unix ->
		    error("file not found ~s: ~p~n", [File, Error]);
		_ -> 
		    %% for windows or nt the hosts file is not always there
		    %% and we don't require it
		    ok
	    end
    end.

%%
%% Load resolver data from Windows registry
%%
win32_load_from_registry(Type) ->
    %% The TcpReg variable enables us to run tests with other registry configurations than
    %% the normal ones 
    TcpReg = case os:getenv("ERL_INET_ETC_DIR") of
		 false -> [];
		 _TReg -> _TReg
	     end,
    {ok, Reg} = win32reg:open([read]),
    {TcpIp,HFileKey} =
    case Type of
	nt ->
	    case TcpReg of
		[] -> 
		    {"\\hklm\\system\\CurrentControlSet\\Services\\TcpIp\\Parameters",
		     "DataBasePath" };
		Other ->
		    {Other,"DataBasePath"}
	    end;
	windows ->
	    case TcpReg of 
		[] ->
		    {"\\hklm\\system\\CurrentControlSet\\Services\\VxD\\MSTCP",
		     "LMHostFile" };
		Other ->
		    {Other,"LMHostFile"}
	    end
    end,
    Result = 
	case win32reg:change_key(Reg,TcpIp) of
	    ok ->
		win32_load1(Reg,Type,HFileKey);
	    {error, _Reason} ->
		error("Failed to locate TCP/IP parameters (is TCP/IP installed)?",
		      [])
	end,
    win32reg:close(Reg),
    Result.

win32_load1(Reg,Type,HFileKey) ->
    Names = [HFileKey, "Domain", "DhcpDomain", 
	     "EnableDNS", "NameServer", "SearchList"],
    case win32_get_strings(Reg, Names) of
	[DBPath0, Domain, DhcpDomain, 
	 _EnableDNS, NameServers0, Search] ->
	    inet_db:set_domain(
	      case Domain of "" -> DhcpDomain; _ -> Domain end),
	    NameServers = win32_split_line(NameServers0,Type),
	    AddNs = fun(Addr) ->
			    case inet_parse:address(Addr) of
				{ok, Address} ->
				    inet_db:add_ns(Address);
				{error, _} ->
				    error("Bad TCP/IP address in registry", [])
			    end
		    end,
	    foreach(AddNs, NameServers),
	    Searches0 = win32_split_line(Search,Type),
	    Searches = case member(Domain, Searches0) of
			   true  -> Searches0;
			   false -> [Domain|Searches0]
		       end,
	    foreach(fun(D) -> inet_db:add_search(D) end, Searches),
	    if Type =:= nt ->
		    DBPath = win32reg:expand(DBPath0),
		    load_hosts(filename:join(DBPath, "hosts"),nt);
		Type =:= windows ->
		    load_hosts(filename:join(DBPath0,""),windows)
	    end,
%% Maybe activate this later as an optimization
%% For now we use native always as the SAFE way
%%	    case NameServers of
%%		[] -> inet_db:set_lookup([native, file]);
%%		_  -> inet_db:set_lookup([dns, file, native])
%%	    end;
	    true;
	{error, _Reason} ->
	    error("Failed to read TCP/IP parameters from registry", [])
    end.

win32_split_line(Line,nt) -> inet_parse:split_line(Line);
win32_split_line(Line,windows) -> string:tokens(Line, ",").

win32_get_strings(Reg, Names) ->
    win32_get_strings(Reg, Names, []).

win32_get_strings(Reg, [Name|Rest], Result) ->
    case win32reg:value(Reg, Name) of
	{ok, Value} when is_list(Value) ->
	    win32_get_strings(Reg, Rest, [Value|Result]);
	{ok, _NotString} ->
	    {error, not_string};
	{error, _Reason} ->
	    win32_get_strings(Reg, Rest, [""|Result])
    end;
win32_get_strings(_, [], Result) ->
    lists:reverse(Result).

%%
%% Load host data from VxWorks hostShow command
%%

vxworks_load_hosts() ->
    HostShow = os:cmd("hostShow"),
    case check_hostShow(HostShow) of
	Hosts when is_list(Hosts) ->
	    case inet_parse:hosts_vxworks({chars, Hosts}) of
		{ok, Ls} ->
		    foreach(
		      fun({IP, Name, Aliases}) -> 
			      inet_db:add_host(IP, [Name|Aliases])
		      end,
		      Ls);
		{error,Reason} ->
		    error("parser error VxWorks hostShow ~s", [Reason])
	    end;
	_Error ->
	    error("error in VxWorks hostShow~s~n", [HostShow])
    end.

%%
%% Check if hostShow yields at least two line; the first one
%% starting with "hostname", the second one starting with
%% "--------".
%% Returns: list of hosts in VxWorks notation
%% rows of 'Name          IP                [Aliases]  \n'
%% if hostShow yielded these two lines, false otherwise.
check_hostShow(HostShow) ->
    check_hostShow(["hostname", "--------"], HostShow).

check_hostShow([], HostShow) ->
    HostShow;
check_hostShow([String_match|Rest], HostShow) ->
    case lists:prefix(String_match, HostShow) of
	true ->
	    check_hostShow(Rest, next_line(HostShow));
	false ->
	    false
    end.

next_line([]) ->
    [];
next_line([$\n|Rest]) ->
    Rest;
next_line([_First|Rest]) ->
    next_line(Rest).

read_rc() ->
    {RcFile,CfgList} = read_inetrc(),
    case extract_cfg_files(CfgList, [], []) of
	{CfgFiles,CfgList1} ->
	    {RcFile,CfgFiles,CfgList1};
	error ->
	    {error,[],[]}
    end.



extract_cfg_files([E = {file,Type,_File} | Es], CfgFiles, CfgList) ->
    extract_cfg_files1(Type, E, Es, CfgFiles, CfgList);
extract_cfg_files([E = {registry,Type} | Es], CfgFiles, CfgList) ->
    extract_cfg_files1(Type, E, Es, CfgFiles, CfgList);
extract_cfg_files([E | Es], CfgFiles, CfgList) ->
    extract_cfg_files(Es, CfgFiles, [E | CfgList]);
extract_cfg_files([], CfgFiles, CfgList) ->
    {reverse(CfgFiles),reverse(CfgList)}.

extract_cfg_files1(Type, E, Es, CfgFiles, CfgList) ->
    case valid_type(Type) of
	true ->
	    extract_cfg_files(Es, [E | CfgFiles], CfgList);
	false ->
	    error("invalid config value ~w in inetrc~n", [Type]),
	    error
    end.

valid_type(resolv) ->            true;
valid_type(host_conf_freebsd) -> true;
valid_type(host_conf_bsdos) ->   true;
valid_type(host_conf_linux) ->   true;
valid_type(nsswitch_conf) ->     true;
valid_type(hosts) ->             true;
valid_type(win32) ->             true;
valid_type(_) ->                 false.

read_inetrc() ->
   case application:get_env(inetrc) of
       {ok,File} ->
	   try_get_rc(File);
       _ ->
	   case os:getenv("ERL_INETRC") of
	       false ->
		   {nofile,[]};
	       File ->
		   try_get_rc(File)
	   end
   end.

try_get_rc(File) ->
    case get_rc(File) of
	error -> {nofile,[]};
	Ls ->    {File,Ls}
    end.    

get_rc(File) ->
    case get_file(File) of
	{ok,Bin} ->
	    case parse_inetrc(Bin) of
		{ok,Ls} -> 
		    Ls;
		_Error -> 
		    error("parse error in ~s~n", [File]),
		    error
	    end;
	_Error -> 
	    error("file ~s not found~n", [File]),
	    error
    end.

%% XXX Check if we really need to prim load the stuff
get_file(File) ->
    case erl_prim_loader:get_file(File) of
	{ok,Bin,_} -> {ok,Bin};
	Error -> Error
    end.

error(Fmt, Args) ->
    error_logger:error_msg("inet_config: " ++ Fmt, Args).

warning(Fmt, Args) ->
    case application:get_env(kernel,inet_warnings) of
	%{ok,silent} -> ok;
	{ok,on} -> 
	    error_logger:info_msg("inet_config:" ++ Fmt, Args);
	_ ->
	    ok
    end.

%% 
%% Parse inetrc, i.e. make a binary of a term list.
%% The extra newline is to let the user ignore the whitespace !!!
%% Ignore leading whitespace before a token (due to bug in erl_scan) !
%% 
parse_inetrc(Bin) ->
    Str = binary_to_list(Bin) ++ "\n", 
    parse_inetrc(Str, 1, []).

parse_inetrc_skip_line([], _Line, Ack) ->
    {ok, reverse(Ack)};
parse_inetrc_skip_line([$\n|Str], Line, Ack) ->
    parse_inetrc(Str, Line+1, Ack);
parse_inetrc_skip_line([_|Str], Line, Ack) ->
    parse_inetrc_skip_line(Str, Line, Ack).

parse_inetrc([$%|Str], Line, Ack) ->
    parse_inetrc_skip_line(Str, Line, Ack);
parse_inetrc([$\s|Str], Line, Ack) ->
    parse_inetrc(Str, Line, Ack);
parse_inetrc([$\n |Str], Line, Ack) ->
    parse_inetrc(Str, Line+1, Ack);
parse_inetrc([$\t|Str], Line, Ack) ->
    parse_inetrc(Str, Line, Ack);
parse_inetrc([], _, Ack) ->
    {ok, reverse(Ack)};


%% The clauses above are here due to a bug in erl_scan (OTP-1449).

parse_inetrc(Str, Line, Ack) ->
    case erl_scan:tokens([], Str, Line) of
	{done, {ok, Tokens, EndLine}, MoreChars} ->
	    case erl_parse:parse_term(Tokens) of
		{ok, Term} ->
		    parse_inetrc(MoreChars, EndLine, [Term|Ack]);
		Error ->
		    {error, {'parse_inetrc', Error}}
	    end;
	{done, {eof, _}, _} ->
	    {ok, reverse(Ack)};
	{done, Error, _} ->
	    {error, {'scan_inetrc', Error}};
	{more, _} -> %% Bug in erl_scan !!
	    {error, {'scan_inetrc', {eof, Line}}}
    end.
