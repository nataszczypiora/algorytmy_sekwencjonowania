from Bio.Align import PairwiseAligner
from Bio import SeqIO

import tracemalloc
import time

#Gotoh local alignment algorithm
def bioPython_default_local_aligner(a, b):
    aligner = PairwiseAligner()
    aligner.mode = 'local'
    aligner.match_score = 2
    aligner.mismatch_score = -3
    aligner.open_gap_score = -7
    aligner.extend_gap_score = -2

    sequence1 = SeqIO.read('./resource/fasta' + str(a) +'.fasta', 'fasta')
    sequence2 = SeqIO.read('./resource/fasta' + str(b) +'.fasta', 'fasta')
    alignments = aligner.align(sequence1.seq, sequence2.seq)


def bioPython_default_local_aligner_test():
    start_time = time.time()
    tracemalloc.start()
    for i in range(93):
        bioPython_default_local_aligner(i, i + 1)
        current, peak = tracemalloc.get_traced_memory()

    print(f"Current memory usage is {current / 10 ** 6}MB; Peak was {peak / 10 ** 6}MB")
    tracemalloc.stop()
    print("--- %s seconds ---" % (time.time() - start_time))

bioPython_default_local_aligner_test()