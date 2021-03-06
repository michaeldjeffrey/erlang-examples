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
%%
%%----------------------------------------------------------------------
%% Purpose: The top supervisor for the inets application
%%----------------------------------------------------------------------

-module(inets_sup).

-behaviour(supervisor).

-export([init/1]).

%%%=========================================================================
%%%  Supervisor callback
%%%=========================================================================
init([]) ->
    SupFlags = {one_for_one, 10, 3600},
    Children = children(), 
    {ok, {SupFlags, Children}}.

%%%=========================================================================
%%%  Internal functions
%%%=========================================================================
get_services() ->
    case (catch application:get_env(inets, services)) of
	{ok, Services} ->
	    Services;
	_ ->
	    []
    end.

children() ->
    Services = get_services(),
    HttpdServices = [Service || Service <- Services, is_httpd(Service)],
    HttpcServices =  [Service || Service <- Services, is_httpc(Service)],
    TftpdServices =  [Service || Service <- Services, is_tftpd(Service)],
    [ftp_child_spec(), httpc_child_spec(HttpcServices), 
     httpd_child_spec(HttpdServices), tftpd_child_spec(TftpdServices)].

ftp_child_spec() ->
    Name = ftp_sup,
    StartFunc = {ftp_sup, start_link, []},
    Restart = permanent, 
    Shutdown = infinity,
    Modules = [ftp_sup],
    Type = supervisor,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.


httpc_child_spec(HttpcServices0) ->
    HttpcServices = default_profile(HttpcServices0, []),
    Name = httpc_sup,
    StartFunc = {httpc_sup, start_link, [HttpcServices]},
    Restart = permanent, 
    Shutdown = infinity,
    Modules = [httpc_sup],
    Type = supervisor,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

httpd_child_spec(HttpdServices) ->
    Name = httpd_sup,
    StartFunc = {httpd_sup, start_link, [HttpdServices]},
    Restart = permanent, 
    Shutdown = infinity,
    Modules = [httpd_sup],
    Type = supervisor,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

tftpd_child_spec(TftpServices) ->
    Name = tftp_sup,
    StartFunc = {tftp_sup, start_link, [TftpServices]},
    Restart = permanent, 
    Shutdown = infinity,
    Modules = [tftp_sup],
    Type = supervisor,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

is_httpd({httpd, _}) ->
    true;
is_httpd({httpd, _, _}) ->
    true;
is_httpd(_) ->
    false.

is_httpc({httpc, _}) ->
    true;
is_httpc(_) ->
    false.

is_tftpd({tftpd, _}) ->
    true;
is_tftpd(_) ->
    false.

default_profile([], Acc) ->
    [{httpc, {default, only_session_cookies}} | Acc];
default_profile([{httpc, {default, _}} | _] = Profiles, Acc) ->
    Profiles ++ Acc;
default_profile([Profile | Profiles], Acc) ->
    default_profile(Profiles, [Profile | Acc]).
