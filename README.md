# erlang-elastic-faas-server
A mini "serverless" cloud system built in Erlang! This project mimics services like AWS Lambda or Google Cloud Functions. It features a master server that automatically spins up new worker actors when traffic is high, scales them down when it's quiet, and instantly restarts them if they crash. Developed for the 2025 PCPP course at ITU.

## The Actor Model Approach to Concurrency

The Actor model approaches concurrent programming by utilizing independent, concurrently executing entities (actors) that communicate exclusively through asynchronous message passing, rather than relying on shared memory. By enforcing a strict "no shared state" architecture, this paradigm eliminates the need for complex synchronization mechanisms like locks. Consequently, it inherently prevents common concurrency issues such as data races, enabling the development of highly scalable, fault-tolerant, and distributed systems.

## What it Simulates

It models an elastic fault-tolerant serverless FaaS system using three types of actors:
* **Clients:** These actors send a list of operations for the server to compute.
* **Server:** This actor manages a set of workers in a fault-tolerant and efficient manner. It maintains a minimum number of workers, dynamically creates new ones on-demand for high workloads, reduces the workforce when idle, and instantly restarts workers if they crash.
* **Workers:** These actors simply compute operations sent by the Server. When they are finished, they send the result directly to the client and tell the server that they are done with the computation.

## How to Run and Test

1. **Start the Erlang shell** in your terminal from the directory containing the `.erl` files.
2. **Compile the modules:**
   ```erlang
   1> c(client).
   2> c(server).
   3> c(worker).
   ```
3. Execute a batch of tasks to test elasticity: Use the client to send a list of tasks, specifying the minimum and maximum number of workers (e.g., minimum 2, maximum 5):
   ```erlang
   4> client:send_tasks(Tasks, 2, 5).
   ```
4. Test fault tolerance: Run the crashing example to observe the server catching a worker failure and automatically spawning a replacement:
   ```erlang
   5> client:crashing_example(2, 5).
   ```
