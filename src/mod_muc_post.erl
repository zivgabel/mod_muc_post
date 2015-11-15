-module(mod_muc_post).
-author('Ziv Gabel').

-behaviour(gen_mod).

-export([start/2,
	 init/2,
	 stop/1,
	 start_link/2,
	 send_muc_message/5]).

-define(PROCNAME, ?MODULE).

-include("ejabberd.hrl").
-include("jlib.hrl").
-include("logger.hrl").

start(Host, Opts) ->
	error_logger:info_msg("MOD_ZIV - Starting mod_muc_post"),
	register(?PROCNAME,spawn(?MODULE, init, [Host, Opts])),  
	ok.

init(Host, _Opts) ->
	inets:start(),
	ssl:start(),
	ejabberd_hooks:add(muc_filter_message, Host, ?MODULE, send_muc_message, 10),
	ok.

stop(Host) ->
	error_logger:info_msg("MOD_ZIV - Stopping mod_muc_post"),
	ejabberd_hooks:delete(muc_filter_message, Host,?MODULE, send_muc_message, 10),
	ok.

%%
%% The main function that post the information to the http server.
%%

send_muc_message(Stanza, MUCState, RoomJID, FromJID, FromNick) ->
	PostUrl=get_post_url(),
	Body = xml:get_subtag(Stanza, <<"body">>),
	BodyC =  binary_to_list(xml:get_tag_cdata(Body)),
	Nick =  binary_to_list(FromNick),
%%	FromJID cones in the format:
%%		{jid,<<"user">>,<<"example.com">>,<<"user">>,<<"user">>,<<"example.com">>,<<"user">>}
%%	Creating a the from data as user@example.com
	From=binary_to_list(element(2,FromJID))++"@"++binary_to_list(element(3,FromJID)),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[MUCState]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[PostUrl]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[BodyC]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[RoomJID]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[FromJID]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[From]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[Nick]),
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[Stanza]),
	Post=parse_muc_stanza(element(3,Stanza))++"&message="++BodyC++"&from="++From,
	error_logger:info_msg("MOD_ZIV - INFO - ~p",[Post]),
    	httpc:request(post, {PostUrl, [], "application/x-www-form-urlencoded", Post},[],[]),

    Stanza.

start_link(Host, Opts) ->
    Proc = gen_mod:get_module_proc(Host, ?PROCNAME),
    gen_server:start_link({local, Proc}, ?MODULE, [Host, Opts], []).

%%
%% Stanza looks something like: 
%% 	{xmlel,<<"message">>,[{<<"xml:lang">>,<<"en">>},{<<"type">>,<<"groupchat">>},{<<"to">>,<<"123456789@example.com">>},{<<"id">>,<<"aac1a">>}],[{xmlcdata,<<"\n">>},{xmlel,<<"body">>,[],[{xmlcdata,<<"awdasdddsdasasdadsds">>}]},{xmlcdata,<<"\n">>},{xmlel,<<"nick">>,[{<<"xmlns">>,<<"http://jabber.org/protocol/nick">>}],[{xmlcdata,<<"User1">>}]},{xmlcdata,<<"\n">>}]}
%% The function will extract the message part:
%% 	[{<<"xml:lang">>,<<"en">>},{<<"type">>,<<"groupchat">>},{<<"to">>,<<"123456789@example.com">>},{<<"id">>,<<"aac1a">>}]
%% Then it will convert it to http post body format
%% In this example the output will be:
%% 	xml:lang=en&type=groupchat&to=123456789@example.com&id-aac1a
%% This value (Url encoded) will be returnd.
%%

parse_muc_stanza(L)->parse_muc_stanza(length(L),L,"").
parse_muc_stanza(0,T,S) -> S;
parse_muc_stanza(N,T,S) when N > 0 ->
        E=element(N,list_to_tuple(T)),
        Add1 = binary_to_list(element(1,E)) ++ "=" ++ binary_to_list(element(2,E)),
        Add2 = if S == "" -> Add1;
                true -> "&" ++ Add1
                end,
        parse_muc_stanza(N-1,T,S++Add2).

%% 
%% Extract the post url from the configuration
%%

get_post_url() ->
	binary_to_list(gen_mod:get_module_opt(global, ?MODULE, post_url,<<"">>)).
