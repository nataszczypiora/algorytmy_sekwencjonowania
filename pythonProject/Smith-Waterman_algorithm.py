import os
import tracemalloc
import time


def smith_waterman_algorithm(a, b):
    command = 'fasta36-36.3.8/bin/ssearch36' + ' ./resource/fasta' + str(a) +'.fasta' + ' ./resource/fasta' + str(b) +'.fasta'
    stream = os.popen(command)
    output = stream.read()


def smith_waterman_test():
    start_time = time.time()
    tracemalloc.start()
    for i in range(93):
        smith_waterman_algorithm(i, i + 1)
    current, peak = tracemalloc.get_traced_memory()
    print(f"Current memory usage is {current / 10 ** 6}MB; Peak was {peak / 10 ** 6}MB")
    tracemalloc.stop()
    print("--- %s seconds ---" % (time.time() - start_time))


smith_waterman_test()