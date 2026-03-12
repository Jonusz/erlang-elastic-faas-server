-module(client).
-export([start/1,init/1,
         send_tasks/2,send_tasks/3,
         example_send_tasks/5, crashing_example/2]).
-include("defs.hrl").

% 1. State
-record(client_state, {server_pid}).

% 2. Start
start(ServerPID) ->
    spawn(?MODULE, init, [ServerPID]).

% 3. Initialization
init(ServerPID) ->
    State=#client_state{server_pid=ServerPID},
    loop(State).

% 4. Behavior upon receiving messages
loop(State) ->
    receive
        {compute, Tasks} ->
            handle_compute(Tasks, State);
        {result, Task, Result} ->
            handle_result(Task, Result, State)
    end.

% 5. Message handlers
handle_compute(Tasks, State = #client_state{server_pid = ServerPID}) -> % two arguments fit helper function bellow
    ServerPID ! {compute, self(), Tasks},
    loop(State).

handle_result(Task, Result, State) -> % three arguments wait for being called from worker
    io:format("The result to task ~p is ~p~n",[Task, Result]),
    loop(State).


% Helper functions to check the behavior of the system

% This function should work for exercise 13.1.1 
send_tasks(Tasks, NumWorkers) ->
    ServerPID = server:start(NumWorkers), % becaause we spawn server, it returns its PID
    ClientPID = client:start(ServerPID),
    ClientPID ! {compute, Tasks},
    ServerPID.

% This function should work for exercises 13.1.2 & 13.1.4
send_tasks(Tasks, MinWorkers, MaxWorkers) ->
    ServerPID = server:start(MinWorkers, MaxWorkers),
    ClientPID = client:start(ServerPID),
    ClientPID ! {compute, Tasks},
    ServerPID.

% This function should work for exercise 13.1.3
crashing_example(MinWorkers, MaxWorkers) ->
    T1 = #task{function=fun (X,Y) -> X+Y end, arguments=[42,42]},
    T2 = #task{function=fun (X,Y) -> X-Y end, arguments=[42,42]},
    T3 = #task{function=fun (X,Y) -> X*Y end, arguments=[42,42]},
    T4 = #task{function=fun (X,Y) -> (X+Y)/0 end, arguments=[42,42]},
    Tasks = [T1,T2,T3,T4],
    send_tasks(Tasks, MinWorkers, MaxWorkers).

% This is a helper function to send NumTasks times the same task,
% which is defined by Function and Arguments
example_send_tasks(NumTasks, Function, Arguments, MinWorkers, MaxWorkers) ->
    T = #task{function=Function, arguments=Arguments},
    Tasks = lists:duplicate(NumTasks, T),
    send_tasks(Tasks, MinWorkers, MaxWorkers).
