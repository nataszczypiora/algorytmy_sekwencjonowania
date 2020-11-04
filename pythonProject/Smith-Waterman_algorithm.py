import itertools
import numpy as np

#Do znalezienia podobieństwa między b a a, algorytm Smith-Waterman najpierw oblicza macierz punktacji.
#Poniższy kod oblicza tę macierz dla dwóch ciągów a i b
#z domyślnym liniowym kosztem przerwy oraz liniową punktacją znalezienie pary.
#Domyślne wartości wybrane zostały z artykułu na wikipedii: https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm#Example
from Bio import SeqIO


def matrix(a, b, match_score=3, gap_cost=2):
    H = np.zeros((len(a) + 1, len(b) + 1), np.int) #tworzenie macierzy

    for i, j in itertools.product(range(1, H.shape[0]), range(1, H.shape[1])): #nadawanie wartości pól
        match = H[i - 1, j - 1] + (match_score if a[i - 1] == b[j - 1] else - match_score)
        delete = H[i - 1, j] - gap_cost #delacja
        insert = H[i, j - 1] - gap_cost #insercja
        H[i, j] = max(match, delete, insert, 0)
    return H


def traceback(H, b, b_='', old_i=0):
    H_flip = np.flip(np.flip(H, 0), 1) #algorytm wymaga odczytywania od tyłu, więc macierz musiała zostać odwrócona
    i_, j_ = np.unravel_index(H_flip.argmax(), H_flip.shape)
    i, j = np.subtract(H.shape, (i_ + 1, j_ + 1))  # (i, j) are **last** indexes of H.max()
    if H[i, j] == 0:
        return b_, j
    b_ = b[j - 1] + '-' + b_ if old_i - i > 1 else b[j - 1] + b_
    return traceback(H[0:i, 0:j], b, b_, i)


#Wywołanie wyżej wymienionych kroków algorytmu
def smith_waterman(a, b, match_score=3, gap_cost=2):
    a, b = a.upper(), b.upper()
    H = matrix(a, b, match_score, gap_cost)
    b_, pos = traceback(H, b)
    return pos, pos + len(b_)

seq1 = next(SeqIO.parse("seq1.fasta", "fasta"))
seq2 = next(SeqIO.parse("seq2.fasta", "fasta"))
print(smith_waterman(seq1.seq, seq2.seq))
