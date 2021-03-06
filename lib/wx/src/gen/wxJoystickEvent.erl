%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2008-2009. All Rights Reserved.
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
%% This file is generated DO NOT EDIT

%% @doc See external documentation: <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html">wxJoystickEvent</a>.
%% <dl><dt>Use {@link wxEvtHandler:connect/3.} with EventType:</dt>
%% <dd><em>joy_button_down</em>, <em>joy_button_up</em>, <em>joy_move</em>, <em>joy_zmove</em></dd></dl>
%% See also the message variant {@link wxEvtHandler:wxJoystick(). #wxJoystick{}} event record type.
%%
%% <p>This class is derived (and can use functions) from: 
%% <br />{@link wxEvent}
%% </p>
%% @type wxJoystickEvent().  An object reference, The representation is internal
%% and can be changed without notice. It can't be used for comparsion
%% stored on disc or distributed for use on other nodes.

-module(wxJoystickEvent).
-include("wxe.hrl").
-export([buttonDown/1,buttonDown/2,buttonIsDown/1,buttonIsDown/2,buttonUp/1,
  buttonUp/2,getButtonChange/1,getButtonState/1,getJoystick/1,getPosition/1,
  getZPosition/1,isButton/1,isMove/1,isZMove/1]).

%% inherited exports
-export([getId/1,getSkipped/1,getTimestamp/1,isCommandEvent/1,parent_class/1,
  resumePropagation/2,shouldPropagate/1,skip/1,skip/2,stopPropagation/1]).

%% @hidden
parent_class(wxEvent) -> true;
parent_class(_Class) -> erlang:error({badtype, ?MODULE}).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @equiv buttonDown(This, [])
buttonDown(This)
 when is_record(This, wx_ref) ->
  buttonDown(This, []).

%% @spec (This::wxJoystickEvent(), [Option]) -> bool()
%% Option = {but, integer()}
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventbuttondown">external documentation</a>.
buttonDown(#wx_ref{type=ThisT,ref=ThisRef}, Options)
 when is_list(Options) ->
  ?CLASS(ThisT,wxJoystickEvent),
  MOpts = fun({but, But}, Acc) -> [<<1:32/?UI,But:32/?UI>>|Acc];
          (BadOpt, _) -> erlang:error({badoption, BadOpt}) end,
  BinOpt = list_to_binary(lists:foldl(MOpts, [<<0:32>>], Options)),
  wxe_util:call(?wxJoystickEvent_ButtonDown,
  <<ThisRef:32/?UI, 0:32,BinOpt/binary>>).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @equiv buttonIsDown(This, [])
buttonIsDown(This)
 when is_record(This, wx_ref) ->
  buttonIsDown(This, []).

%% @spec (This::wxJoystickEvent(), [Option]) -> bool()
%% Option = {but, integer()}
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventbuttonisdown">external documentation</a>.
buttonIsDown(#wx_ref{type=ThisT,ref=ThisRef}, Options)
 when is_list(Options) ->
  ?CLASS(ThisT,wxJoystickEvent),
  MOpts = fun({but, But}, Acc) -> [<<1:32/?UI,But:32/?UI>>|Acc];
          (BadOpt, _) -> erlang:error({badoption, BadOpt}) end,
  BinOpt = list_to_binary(lists:foldl(MOpts, [<<0:32>>], Options)),
  wxe_util:call(?wxJoystickEvent_ButtonIsDown,
  <<ThisRef:32/?UI, 0:32,BinOpt/binary>>).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @equiv buttonUp(This, [])
buttonUp(This)
 when is_record(This, wx_ref) ->
  buttonUp(This, []).

%% @spec (This::wxJoystickEvent(), [Option]) -> bool()
%% Option = {but, integer()}
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventbuttonup">external documentation</a>.
buttonUp(#wx_ref{type=ThisT,ref=ThisRef}, Options)
 when is_list(Options) ->
  ?CLASS(ThisT,wxJoystickEvent),
  MOpts = fun({but, But}, Acc) -> [<<1:32/?UI,But:32/?UI>>|Acc];
          (BadOpt, _) -> erlang:error({badoption, BadOpt}) end,
  BinOpt = list_to_binary(lists:foldl(MOpts, [<<0:32>>], Options)),
  wxe_util:call(?wxJoystickEvent_ButtonUp,
  <<ThisRef:32/?UI, 0:32,BinOpt/binary>>).

%% @spec (This::wxJoystickEvent()) -> integer()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventgetbuttonchange">external documentation</a>.
getButtonChange(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_GetButtonChange,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> integer()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventgetbuttonstate">external documentation</a>.
getButtonState(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_GetButtonState,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> integer()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventgetjoystick">external documentation</a>.
getJoystick(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_GetJoystick,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> {X::integer(),Y::integer()}
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventgetposition">external documentation</a>.
getPosition(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_GetPosition,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> integer()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventgetzposition">external documentation</a>.
getZPosition(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_GetZPosition,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventisbutton">external documentation</a>.
isButton(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_IsButton,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventismove">external documentation</a>.
isMove(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_IsMove,
  <<ThisRef:32/?UI>>).

%% @spec (This::wxJoystickEvent()) -> bool()
%% @doc See <a href="http://www.wxwidgets.org/manuals/stable/wx_wxjoystickevent.html#wxjoystickeventiszmove">external documentation</a>.
isZMove(#wx_ref{type=ThisT,ref=ThisRef}) ->
  ?CLASS(ThisT,wxJoystickEvent),
  wxe_util:call(?wxJoystickEvent_IsZMove,
  <<ThisRef:32/?UI>>).

 %% From wxEvent 
%% @hidden
stopPropagation(This) -> wxEvent:stopPropagation(This).
%% @hidden
skip(This, Options) -> wxEvent:skip(This, Options).
%% @hidden
skip(This) -> wxEvent:skip(This).
%% @hidden
shouldPropagate(This) -> wxEvent:shouldPropagate(This).
%% @hidden
resumePropagation(This,PropagationLevel) -> wxEvent:resumePropagation(This,PropagationLevel).
%% @hidden
isCommandEvent(This) -> wxEvent:isCommandEvent(This).
%% @hidden
getTimestamp(This) -> wxEvent:getTimestamp(This).
%% @hidden
getSkipped(This) -> wxEvent:getSkipped(This).
%% @hidden
getId(This) -> wxEvent:getId(This).
