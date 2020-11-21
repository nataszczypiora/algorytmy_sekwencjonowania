import os
import tracemalloc
import time


def FASTA_algorithm(a, b):
    command = 'fasta36-36.3.8/bin/fasta36' + ' ./resource/fasta' + str(a) +'.fasta' + ' ./resource/fasta' + str(b) +'.fasta'
    stream = os.popen(command)
    output = stream.read()


def FASTA_test():
    start_time = time.time()
    tracemalloc.start()
    for i in range(93):
        FASTA_algorithm(i, i + 1)
    current, peak = tracemalloc.get_traced_memory()

    print(f"Current memory usage is {current / 10 ** 6}MB; Peak was {peak / 10 ** 6}MB")
    tracemalloc.stop()
    print("--- %s seconds ---" % (time.time() - start_time))


FASTA_test()

