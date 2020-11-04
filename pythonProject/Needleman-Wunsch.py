from Bio import Align, SeqIO, pairwise2

#porównywanie sekwencji z dokumentacji BioPython, algorytm wykorzystany do Needleman-Wunsch
aligner = Align.PairwiseAligner()
aligner = Align.PairwiseAligner(match_score=1.0)
seq1 = next(SeqIO.parse("seq1.fasta", "fasta"))
seq2 = next(SeqIO.parse("seq2.fasta", "fasta"))
score = aligner.score(seq1.seq, seq2.seq)
print(score) #64
alignments = aligner.align(seq1.seq, seq2.seq)
print(aligner.algorithm) #Needleman-Wunsch
for alignment in alignments:
     print(alignment)





