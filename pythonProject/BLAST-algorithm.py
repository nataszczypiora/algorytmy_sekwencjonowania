from Bio.Blast.Applications import NcbiblastpCommandline
from io import StringIO
from Bio.Blast import NCBIXML
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio import SeqIO
from Bio import pairwise2
from Bio.Align import substitution_matrices

# Create two sequence files
seq1 = SeqRecord(Seq("AGTAACAAGGTTTCCGTAGGTTTTTTTGCGGAAGGATCATTGATGAGACCGTGGAATAAAC"),
                   id="seq1")
seq2 = SeqRecord(Seq("AGTAACAAGGTTTCCGTAGGTTTTTTTGCGGAAGGATCATTGATGAGACCGTGGAATAAAC"),
                   id="seq2")
blosum62 = substitution_matrices.load("BLOSUM62")
SeqIO.write(seq1, "seq1.fasta", "fasta")
SeqIO.write(seq2, "seq2.fasta", "fasta")

#Porownywanie sekwencji z dokumentacji BioPython (nie jest podane jaki algorytm)
alignments = pairwise2.align.globalds(seq1.seq, seq2.seq, blosum62, -10, -0.5)
print(pairwise2.format_alignment(*alignments[0]))

# Run BLAST and parse the output as XML, niby blast, ale coś nie tak z nim jest
output = NcbiblastpCommandline(query="seq1.fasta", subject="seq2.fasta", outfmt=5)()[0]
output
blast_result_record = NCBIXML.read(StringIO(output))

# Print some information on the result
for alignment in blast_result_record.alignments:
    for hsp in alignment.hsps:
        print('****Alignment****')
        print('sequence:', alignment.title)
        print('length:', alignment.length)
        print('e value:', hsp.expect)
        print(hsp.query)
        print(hsp.match)
