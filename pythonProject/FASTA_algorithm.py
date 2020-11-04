from Bio import SeqIO
#Nic tu nie działa, więc na razie tego nie ruszam
for seq_record in SeqIO.parse("resource/ls_orchid.fasta", "fasta"):
    #print(seq_record.id)
    #print(repr(seq_record.seq))
    #print(len(seq_record))
    print(seq_record.seq)