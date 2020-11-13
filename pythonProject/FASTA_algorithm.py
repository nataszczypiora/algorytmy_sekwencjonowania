import os
import tracemalloc

tracemalloc.start()
stream = os.popen('fasta36-36.3.8/bin/fasta36 seq1.fasta seq2.fasta')
current, peak = tracemalloc.get_traced_memory()
output = stream.read()
print(output)
print(f"Current memory usage is {current / 10**6}MB; Peak was {peak / 10**6}MB")
tracemalloc.stop()