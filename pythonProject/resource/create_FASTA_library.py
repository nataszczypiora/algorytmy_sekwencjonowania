from Bio import SeqIO


def create_FASTA_library_from_one_file():
    with open("ls_orchid.fasta", "r") as handle:
        i = 0
        for seq1 in SeqIO.parse(handle, "fasta"):
            SeqIO.write(seq1, "fasta" + str(i) + ".fasta", "fasta")
            i = i + 1


create_FASTA_library_from_one_file()
