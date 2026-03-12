% This header file is used so that we use a unified format for tasks
% that can be used by worker actors.

% The first element in the record must be a function, and the second
% element is a list of parameters for the function.

% For example, we can define a task to add the numbers 2 and 3---i.e.,
% computing 2+3---as follows: #task{function=fun (X,Y) -> X+Y end, arguments=[2,3]}.

% You can find a few more examples of tasks in the API functions from
% the client module.

-record(task, {function, arguments}).
