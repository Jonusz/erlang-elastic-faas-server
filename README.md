# erlang-elastic-faas-server
A mini "serverless" cloud system built in Erlang! This project mimics services like AWS Lambda or Google Cloud Functions. It features a master server that automatically spins up new worker actors when traffic is high, scales them down when it's quiet, and instantly restarts them if they crash. Developed for the 2025 PCPP course at ITU.
