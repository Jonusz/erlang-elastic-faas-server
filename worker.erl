-module(worker).
-export([start/1, init/1]).
-include("defs.hrl").

% 1. State
-record(worker_state, {server}). % records are like classes with fields in java

% 2. Start
start(ServerPID) ->
    %spawn is specyfic function that creates a new process
    % it always take only 3 arguments: module, function, list of arguments
    spawn(?MODULE, init, [ServerPID]). % ?Module is the macro, an atom. it expands to 'worker'. If you would change name of module in line 3, it will be changed automatically here.

% 3. Initialization
init(ServerPID) ->
    State = #worker_state{server=ServerPID}, % it is contructor 
    loop(State).

% 4. Behavior upon receiving messages
loop(State) ->
    receive
        {compute, SenderPID, Task} ->
            handle_compute(SenderPID, Task, State);
        stop ->
            exit(normal)
    end.

% 5. Message handlers
handle_compute(SenderPID, 
               Task = #task{function = F, arguments=Args}, % function comes from defs.hrl, F is our defined name for function, sam for args
               State = #worker_state{server = ServerPID}) ->
    Result = apply(F, Args),
    SenderPID ! {result, Task, Result}, % result -> atom, Result -> variable
    ServerPID ! {work_done, self()},
    %io:format("Worker ~p completed task ~p with result ~p~n",[self(), Task, Result]),
    loop(State).
