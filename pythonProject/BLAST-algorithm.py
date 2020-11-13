from Bio.Blast.Applications import NcbiblastnCommandline
import tracemalloc

tracemalloc.start()
output = NcbiblastnCommandline(query="seq1.fasta", subject="seq2.fasta", outfmt=8, out="blast_output.txt")()
current, peak = tracemalloc.get_traced_memory()

print(f"Current memory usage is {current / 10**6}MB; Peak was {peak / 10**6}MB")
tracemalloc.stop()