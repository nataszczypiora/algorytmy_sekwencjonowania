from Bio.Blast.Applications import NcbiblastnCommandline
import tracemalloc
import time


def BLAST(a, b):
    seq1 = "./resource/fasta" + str(a) + ".fasta"
    seq2 = "./resource/fasta" + str(b) + ".fasta"
    output = NcbiblastnCommandline(query=seq1, subject=seq2, outfmt=8, out="./resource/blast_output.txt", task="blastn")()

def BLAST_test():
    tracemalloc.start()
    start_time = time.time()
    for i in range(93):
        BLAST(i, i + 1)
    current, peak = tracemalloc.get_traced_memory()
    print(f"Current memory usage is {current / 10 ** 6}MB; Peak was {peak / 10 ** 6}MB")
    print("--- %s seconds ---" % (time.time() - start_time))
    tracemalloc.stop()


BLAST_test()