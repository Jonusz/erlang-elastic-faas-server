-module(server).
-export([start/1 , start/2]). 
-include("defs.hrl").

% 1. State
-record(state, {
    pending_tasks = [], 
    busy_workers = [], 
    idle_workers = [],
    minimumNoWorkers, 
    maximumNoWorkers }).

% 2. Start without min,max workers
start(NOfWorkers) -> spawn(fun() -> init(NOfWorkers) end).
%fun is a lambda function, it takes parameter NOfWorkers and calls init with it

%start with min,max workers
start(MinWorkers, MaxWorkers) -> spawn(fun() -> init(MinWorkers,MaxWorkers) end).

% 3. Initialization
init(NOfWorkers) ->
    % Create N workers actors 
    Workers = [start_and_monitor_worker() || _ <- lists:seq(1, NOfWorkers)], % self return id of server || for every element on the right so for each element in list, lists:seq generate list from 1 to NOfWorkers
    InitialState = #state{
        idle_workers = Workers, 
        busy_workers = [], 
        pending_tasks = [], 
        minimumNoWorkers = NOfWorkers,
        maximumNoWorkers = NOfWorkers}, % # is record constructor, like new state() in java, minimum,maximum workers are defult to prevent further crash of code
    loop(InitialState). % Variables must start with Uppercase (initialStates -> InitialState)

init(MinWorkers,MaxWorkers) ->
    Workers = [start_and_monitor_worker() || _ <- lists:seq(1, MinWorkers)],
    InitialState = #state{
        idle_workers = Workers, 
        busy_workers = [], 
        pending_tasks=[],
        minimumNoWorkers = MinWorkers, 
        maximumNoWorkers = MaxWorkers},
    loop(InitialState).

% 4. Behavior upon receiving messages
loop(State) ->
    receive
        {compute, SenderPID, Tasks} ->
            NewState = schedule(Tasks, SenderPID, State),
            loop(NewState);
            
        {work_done, WorkerPID} ->
            % pending tasks empty?
            NewState = case State#state.pending_tasks of [] -> % its equal to State.pending_tasks in Java (Empty check)
                %% 1. Remove from busy, Add to idle
                CurrentTotal = length(State#state.busy_workers) + length(State#state.idle_workers),
                if CurrentTotal > State#state.minimumNoWorkers ->
                  WorkerPID!stop,
                  State#state{
                    busy_workers = lists:delete(WorkerPID, State#state.busy_workers)};
                true -> %if there are more idle workers than we need
                    State#state{
                        busy_workers = lists:delete(WorkerPID, State#state.busy_workers), % patern: lists:delete(Item, List)
                        idle_workers = [WorkerPID | State#state.idle_workers] % | push worker PID into head of array
                    }
                end; 
                  
                % pending tasks not empty
                [{NextTask, TaskOwnerPID} | RestPending] -> % pattern match: extracts head {Task, ID} and puts rest into RestPending
                    WorkerPID ! {compute, TaskOwnerPID, NextTask},
                    State#state{pending_tasks=RestPending}
            end, % End of case
            loop(NewState);
        {'DOWN', _Ref, process, WorkerPID, Reason} ->
            case Reason of
                normal ->
                    %this mean that we stoped worker
                    loop(State);
                _-> 
                    io:format("Worker ~p crashed! Reason: ~p. Restarting...~n", [WorkerPID, Reason]),
                    NewWorkerList = lists:delete(WorkerPID,State#state.busy_workers),
                    NewWorker = start_and_monitor_worker(),
                    NewState = State#state{
                        busy_workers = NewWorkerList,
                        idle_workers = [NewWorker | State#state.idle_workers]},
                    loop(NewState)
                end
    end.

% 5. Private functions (Schedule Helper)

% Base Case: List empty? Return State
schedule([], _SenderPID, State) ->
    State;

% Task + Idle Worker available
schedule([Task | RestTasks], SenderPID, State = #state{idle_workers = [Worker | RestIdle]}) -> 
    % Pattern match: [Worker | RestIdle] extracts the first available worker from the list
    
    % 1. Send task
    Worker ! {compute, SenderPID, Task}, 
    
    % 2. Update state
    NewState = State#state{
        idle_workers = RestIdle,
        busy_workers = [Worker | State#state.busy_workers] % | adds Worker to head of busy list
    },
    
    % 3. Recurse
    schedule(RestTasks, SenderPID, NewState);

% Min Max workers
schedule([Task | RestTasks], SenderPID, State) when length(State#state.busy_workers) < State#state.maximumNoWorkers ->
    NewWorker = start_and_monitor_worker(),
    NewWorker ! {compute, SenderPID, Task}, 
    NewState = State#state{
        busy_workers = [NewWorker | State#state.busy_workers] % | adds Worker to head of busy list
    },
    schedule(RestTasks, SenderPID, NewState);


% Task + No Idle Worker (Queue it)
schedule([Task | RestTasks], SenderPID, State) ->
    
    % 1. Update state (Queue task)
    NewPending = State#state.pending_tasks ++ [{Task, SenderPID}], % ++ appends to the end of the list
    NewState = State#state{ pending_tasks = NewPending },
    
    % 2. Recurse
    schedule(RestTasks, SenderPID, NewState).

% monitoring errors in workers
start_and_monitor_worker() ->
    Pid = worker:start(self()),
    erlang:monitor(process,Pid),
    Pid.

