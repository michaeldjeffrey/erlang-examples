%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2009. All Rights Reserved.
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

-module(ex_listCtrl).

-include_lib("wx/include/wx.hrl").

-behavoiur(wx_object).

-export([start/1, init/1, terminate/2,  code_change/3,
	 handle_info/2, handle_call/3, handle_event/2]).

-record(state, 
	{
	  parent,
	  config,
	  notebook
	 }).

start(Config) ->
    wx_object:start_link(?MODULE, Config, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init(Config) ->
        wx:batch(fun() -> do_init(Config) end).
do_init(Config) ->
    Parent = proplists:get_value(parent, Config),  
    Panel = wxPanel:new(Parent, []),

    %% Setup sizers
    MainSizer = wxStaticBoxSizer:new(?wxVERTICAL, Panel, 
				     [{label, "wxListCtrl"}]),

    Notebook = wxNotebook:new(Panel, 1, [{style, ?wxBK_DEFAULT}]),


    ListCtrl1 = wxListCtrl:new(Notebook, [{style, ?wxLC_LIST}]),
    [wxListCtrl:insertItem(ListCtrl1, Int, "Item "++integer_to_list(Int)) ||
	Int <- lists:seq(0,50)],
    ListCtrl2 = create_list_ctrl(Notebook, [{style, ?wxLC_REPORT bor
					     ?wxLC_SINGLE_SEL}]),
    IL = wxImageList:new(16,16),
    wxImageList:add(IL, wxArtProvider:getBitmap("wxART_COPY", [{size, {16,16}}])),
    wxImageList:add(IL, wxArtProvider:getBitmap("wxART_MISSING_IMAGE", [{size, {16,16}}])),
    wxImageList:add(IL, wxArtProvider:getBitmap("wxART_TICK_MARK", [{size, {16,16}}])),
    wxImageList:add(IL, wxArtProvider:getBitmap("wxART_CROSS_MARK", [{size, {16,16}}])),
    wxListCtrl:assignImageList(ListCtrl2, IL, ?wxIMAGE_LIST_SMALL),
    Fun =
	fun(Item) ->
		case Item rem 4 of
		    0 ->
			wxListCtrl:setItemBackgroundColour(ListCtrl2, Item, {240,240,240,255}),
			wxListCtrl:setItemImage(ListCtrl2, Item, 0);
		    1 -> wxListCtrl:setItemImage(ListCtrl2, Item, 1);
		    2 -> wxListCtrl:setItemImage(ListCtrl2, Item, 2),
			 wxListCtrl:setItemBackgroundColour(ListCtrl2, Item, {240,240,240,255});
		    _ -> wxListCtrl:setItemImage(ListCtrl2, Item, 3)
		end
	end,
    wx:foreach(Fun, lists:seq(0,50)),

    ListCtrl3 = create_list_ctrl(Notebook, [{style, ?wxLC_REPORT}]),
    wxListCtrl:setTextColour(ListCtrl3, ?wxBLUE),
    wxListCtrl:setItemBackgroundColour(ListCtrl3,5,?wxRED),
    wxListCtrl:setItemBackgroundColour(ListCtrl3,3,?wxGREEN),
    wxListCtrl:setItemBackgroundColour(ListCtrl3,0,?wxCYAN),

    wxNotebook:addPage(Notebook, ListCtrl1, "List", []),
    wxNotebook:addPage(Notebook, ListCtrl2, "Report", []),
    wxNotebook:addPage(Notebook, ListCtrl3, "Colored multiselect", []),

    wxListCtrl:connect(ListCtrl1, command_list_item_selected, []),
    wxListCtrl:connect(ListCtrl2, command_list_item_selected, []),
    wxListCtrl:connect(ListCtrl3, command_list_item_selected, []),
    %% Add to sizers
    wxSizer:add(MainSizer, Notebook, [{proportion, 1},
				      {flag, ?wxEXPAND}]),

    wxPanel:setSizer(Panel, MainSizer),
    {Panel, #state{parent=Panel, config=Config,
		   notebook = Notebook}}.


%%%%%%%%%%%%
%% Callbacks handled as normal gen_server callbacks
handle_info(Msg, State) ->
    demo:format(State#state.config, "Got Info ~p\n",[Msg]),
    {noreply,State}.

handle_call(Msg, _From, State) ->
    demo:format(State#state.config,"Got Call ~p\n",[Msg]),
    {reply,ok,State}.

%% Async Events are handled in handle_event as in handle_info
handle_event(#wx{obj = _ListCtrl,
		 event = #wxList{itemIndex = Item}},
	     State = #state{}) ->
    demo:format(State#state.config,"Item ~p selected.\n",[Item]),
    {noreply,State};
handle_event(Ev = #wx{}, State = #state{}) ->
    demo:format(State#state.config,"Got Event ~p\n",[Ev]),
    {noreply,State}.

code_change(_, _, State) ->
    {stop, ignore, State}.

terminate(_Reason, _State) ->
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Local functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(FIRST_COL, 0).
-define(SECOND_COL, 1).
-define(THIRD_COL, 2).

create_list_ctrl(Win, Options) ->
    ListCtrl = wxListCtrl:new(Win, Options),
    wxListCtrl:insertColumn(ListCtrl, ?FIRST_COL, "First Col", []),
    wxListCtrl:insertColumn(ListCtrl, ?SECOND_COL, "Second Col", []),
    wxListCtrl:insertColumn(ListCtrl, ?THIRD_COL, "Third Col", []),
    Fun =
	fun(Int) ->
		Name = integer_to_list(Int),
		wxListCtrl:insertItem(ListCtrl, Int, ""),
		wxListCtrl:setItem(ListCtrl, Int, ?FIRST_COL, "First "++Name),
		wxListCtrl:setItem(ListCtrl, Int, ?SECOND_COL, "Second "++Name),
		wxListCtrl:setItem(ListCtrl, Int, ?THIRD_COL, "Third "++Name)
	end,
    wx:foreach(Fun, lists:seq(0,50)),

    ListCtrl.

    
