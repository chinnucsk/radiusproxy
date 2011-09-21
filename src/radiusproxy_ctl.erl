%%%----------------------------------------------------------------------
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 3 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%----------------------------------------------------------------------

-module(radiusproxy_ctl).
-author('lemenkov@gmail.com').

-export([start/0]).
-export([stop/0]).
-export([status/0]).
-export([reload/0]).

start() ->
	error_logger:add_report_handler(erlsyslog, {0, "localhost", 514}),

	application:start(radiusproxy).

stop() ->
	Status = case init:get_plain_arguments() of
		[NodeStr] ->
			Node = list_to_atom(NodeStr),
			try rpc:call(Node, application, stop, [radiusproxy]) of
				{badrpc, _Reason} ->
					2;
				_ ->
					case rpc:call(Node, init, stop, []) of
						{badrpc, _Reason} ->
							2;
						_ ->
							0
					end
			catch _:_ ->
				2
			end;
		_ ->
			1
	end,
	halt(Status).

status() ->
	Status = case init:get_plain_arguments() of
		[NodeStr] ->
			Node = list_to_atom(NodeStr),
			try rpc:call(Node, application, get_application, [radiusproxy]) of
				{badrpc, nodedown} ->
					io:format("stopped (nodedown)"),
					3;
				{badrpc, Reason} ->
					io:format("bad rpc: ~p~n", [Reason]),
					4;
				{ok, radiusproxy} ->
					io:format("running..."),
					0;
				undefined ->
					io:format("stopped (undefined)"),
					3
			catch E:R ->
				io:format("E:R: ~p:~p~n", [E,R]),
				4
			end;
		Other ->
			io:format("Other: ~p~n", [Other]),
			4
	end,
	halt(Status).

reload() ->
	Status = case code:lib_dir(radiusproxy) of
		non_existing ->
			1;
		NewDir ->
			case init:get_plain_arguments() of
				[NodeStr] ->
					Node = list_to_atom(NodeStr),
					application:load(radiusproxy),
					{ok, Modules} = application:get_key(radiusproxy, modules),
					try rpc:call(Node, code, lib_dir, [radiusproxy]) of
						{badrpc, nodedown} ->
							io:format("stopped (nodedown)"),
							3;
						{badrpc, Reason} ->
							io:format("bad rpc: ~p~n", [Reason]),
							4;
						{error, bad_name} ->
							io:format("{error, bad_name}"),
							3;
						_OldDir ->
							try rpc:call(Node, code, replace_path, [radiusproxy, NewDir]) of
								{badrpc, nodedown} ->
									io:format("stopped (nodedown)"),
									3;
								{badrpc, Reason} ->
									io:format("bad rpc: ~p~n", [Reason]),
									4;
								true ->
									lists:foreach(fun(Mod) ->
												{Mod, Bin, File} = code:get_object_code(Mod),
												rpc:call(Node, code, load_binary, [Mod, File, Bin]) end, Modules),
									io:format("path replaced..."),
									0;
								{error, What} ->
									io:format("{error, ~p}", [What]),
									3
							catch E:R ->
								io:format("E:R: ~p:~p~n", [E,R]),
								4
							end
					catch E:R ->
						io:format("E:R: ~p:~p~n", [E,R]),
						4
					end;
				Other ->
					io:format("Other: ~p~n", [Other]),
					4
			end
	end,
	halt(Status).

