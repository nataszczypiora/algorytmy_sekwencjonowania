#!/usr/bin/perl -w

################################################################
# copyright (c) 2014 by William R. Pearson and The Rector &
# Visitors of the University of Virginia */
################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under this License is distributed on an "AS
# IS" BASIS, WITHOUT WRRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.  See the License for the specific language
# governing permissions and limitations under the License. 
################################################################

# ann_feats2l.pl gets an annotation file from fasta36 -V with a line of the form:

# gi|62822551|sp|P00502|GSTA1_RAT Glutathione S-transfer\n  (at least from pir1.lseg)
#
# it must:
# (1) read in the line
# (2) parse it to get the up_acc
# (3) return the tab delimited features
#

# this version can read feature2 uniprot features (acc/pos/end/label/value), but returns sorted start/end domains

use strict;

use DBI;
use Getopt::Long;
use Pod::Usage;

use vars qw($host $db $a_table $port $user $pass);

my %domains = ();
my $domain_cnt = 0;

my $hostname = `/bin/hostname`;

unless ($hostname =~ m/ebi/) {
  ($host, $db, $a_table, $port, $user, $pass)  = ("wrpxdb.its.virginia.edu", "uniprot", "annot2", 0, "web_user", "fasta_www");
}
else {
  ($host, $db, $a_table, $port, $user, $pass)  = ("mysql-pearson", "up_db", "annot", 4124, "web_user", "fasta_www");
}

my ($sstr, $lav, $neg_doms, $no_doms, $no_feats, $shelp, $help, $pfam26) = (0,0,0,0,0,0,0,0);
my ($min_nodom) = (0);

GetOptions(
    "host=s" => \$host,
    "db=s" => \$db,
    "user=s" => \$user,
    "password=s" => \$pass,
    "port=i" => \$port,
    "lav" => \$lav,
    "no_doms" => \$no_doms,
    "no-doms" => \$no_doms,
    "nodoms" => \$no_doms,
    "neg" => \$neg_doms,
    "neg_doms" => \$neg_doms,
    "neg-doms" => \$neg_doms,
    "negdoms" => \$neg_doms,
    "min_nodom=i" => \$min_nodom,
    "min-nodom=i" => \$min_nodom,
    "no_feats" => \$no_feats,
    "no-feats" => \$no_feats,
    "nofeats" => \$no_feats,
    "pfam26" => \$pfam26,
    "sstr" => \$sstr,
    "h|?" => \$shelp,
    "help" => \$help,
    );

pod2usage(1) if $shelp;
pod2usage(exitstatus => 0, verbose => 2) if $help;
pod2usage(1) unless @ARGV;
if ($pfam26) {
  $db = 'pfam26';
  $no_feats = 1;
}

my $connect = "dbi:mysql(AutoCommit=>1,RaiseError=>1):database=$db";
$connect .= ";host=$host" if $host;
$connect .= ";port=$port" if $port;

my $dbh = DBI->connect($connect,
		       $user,
		       $pass
		      ) or die $DBI::errstr;

my @feat_keys = qw(ACT_SITE MOD_RES BINDING SITE METAL VARIANT MUTAGEN);
my @feat_vals = ( '=','*','#','^','!','V','V');

my @dom_keys = qw( DOMAIN REPEAT );
my @dom_vals = ( [ '[', ']'],[ '[', ']']);

my @ssr_keys = qw( SSTR );
my @ssr_vals = ( [ '[', ']']);

my %annot_types = ();

my $get_annot_sub = \&get_fasta_annots;
if ($lav) {
  $no_feats = 1;
  $get_annot_sub = \&get_lav_annots;
}

if ($sstr) {@annot_types{@ssr_keys} = @ssr_vals;}
else {
  @annot_types{@feat_keys} = @feat_vals unless ($no_feats);
  @annot_types{@dom_keys} = @dom_vals unless ($no_doms);
}

if ($neg_doms) {
  $domains{'NODOM'}=0;
}

my $get_annots_id = $dbh->prepare(qq(select acc, pos, end, label, value, len from features2 join $a_table using(acc) where id=? order by pos));
my $get_annots_acc = $dbh->prepare(qq(select acc, pos, end, label, value, len from features2 join $a_table using(acc) where acc=? order by pos));

my $get_annots_refacc = $dbh->prepare(qq(select ref_acc, pos, end, label, value, len from features2 join $a_table using(acc) where ref_acc=? order by pos));

my $get_pfam26_id = $dbh->prepare(qq(select pfamseq_acc as acc, seq_start as pos, seq_end as end, "DOMAIN" as label, pfamA_acc as value, length as len from pfamseq join pfamA_reg_full_significant using(auto_pfamseq) join pfamA using(auto_pfamA) where pfamseq_id=? and domain_evalue_score < 0.001 order by pos));

my $get_pfam26_acc = $dbh->prepare(qq(select pfamseq_acc as acc, seq_start as pos, seq_end as end, "DOMAIN" as label, pfamA_acc as value, length as len from pfamseq join pfamA_reg_full_significant using(auto_pfamseq) join pfamA using(auto_pfamA) where pfamseq_acc=? and domain_evalue_score < 0.001 and in_full=1 order by pos));

my $up_atable = "uniprot." . $a_table;
my $get_pfam26_refacc = $dbh->prepare(qq(select ref_acc, seq_start as pos, seq_end as end, "DOMAIN" as label, pfamA_acc as value, length as len from $up_atable join pfamseq on(acc = pfamseq_acc) join pfamA_reg_full_significant using(auto_pfamseq) join pfamA using(auto_pfamA) where ref_acc=? and domain_evalue_score < 0.001 and in_full=1 order by pos));

my $get_annots_sql = $get_annots_id;
if ($pfam26) { $get_annots_sql = $get_annots_acc;}


my ($tmp, $gi, $sdb, $acc, $id, $use_acc);

unless ($no_feats || $sstr) {
  print "=*:phosphorylation\n";
  print "==".":active site\n";
  print "=@".":site\n";
  print "=^:binding\n";
  print "=!:metal binding\n";
}

# get the query
my ($query, $seq_len) =  @ARGV;
$seq_len = 0 unless defined($seq_len);

$query =~ s/^>//;

my $ANN_F;

my @annots = ();

#if it's a file I can open, read and parse it
if ($query !~ m/\|/ && open($ANN_F, $query)) {

  while (my $a_line = <$ANN_F>) {
    $a_line =~ s/^>//;
    chomp $a_line;
    push @annots, show_annots($a_line, $get_annot_sub);
  }
}
else {
  push @annots, show_annots("$query $seq_len", $get_annot_sub);
}

for my $seq_annot (@annots) {
  print ">",$seq_annot->{seq_info},"\n";
  for my $annot (@{$seq_annot->{list}}) {
    if (!$lav && defined($domains{$annot->[-1]})) {
      $annot->[-1] .= " :".$domains{$annot->[-1]};
    }
    print join("\t",@$annot),"\n";
  }
}

exit(0);

sub show_annots {
  my ($query_len, $get_annot_sub) = @_;

  my ($annot_line, $seq_len) = split(/\s+/,$query_len);

  my %annot_data = (seq_info=>$annot_line);

  if ($annot_line =~ m/^gi\|/) {
    $use_acc = 1;
    ($tmp, $gi, $sdb, $acc, $id) = split(/\|/,$annot_line);
  }
  elsif ($annot_line =~ m/SP:(\w+)/) {
    $use_acc = 0;
    $sdb = 'sp';;
    $id = $1;
  }
  elsif ($annot_line =~ m/TR:(\w+)/) {
    $use_acc = 0;
    $sdb = 'tr';
    $id = $1;
  }
  else {
    $use_acc = 1;
    ($sdb, $acc, $id) = split(/\|/,$annot_line);
  }

  # remove version number
  unless ($use_acc) {
    unless ($pfam26) {
      $get_annots_sql = $get_annots_id;
    }
    else {
      $get_annots_sql = $get_pfam26_id;
    }
    $get_annots_sql->execute($id);
  }
  else {
    unless ($pfam26) {
      unless ($sdb =~ m/ref/) {
	$get_annots_sql = $get_annots_acc;
      }
      else {
	$get_annots_sql = $get_annots_refacc;
      }
    }
    else {
      unless ($sdb =~ m/ref/) {
	$get_annots_sql = $get_pfam26_acc;
      }
      else {
	$get_annots_sql = $get_pfam26_refacc;
      }
    }
    $acc =~ s/\.\d+$//;
    $get_annots_sql->execute($acc);
  }

  $annot_data{list} = $get_annot_sub->(\%annot_types, $get_annots_sql, $seq_len);

  return \%annot_data;
}

sub get_fasta_annots {
  my ($annot_types, $get_annots_sql, $seq_len) = @_;

  my ($acc, $pos, $end, $label, $value, $comment, $len);

  $seq_len = 0;

  my @feats2 = ();	# features with start/stop, for checking overlap, adding negative
  my @sites = ();	# sites with one position

  while (($acc, $pos, $end, $label, $value, $len) = $get_annots_sql->fetchrow_array()) {
    $seq_len = $len if ($len > $seq_len);
    if ($annot_types->{$label}) {
      if ($label =~ m/VARIANT/) {
	my ($aa_res, $comment) = split(/\(/,$value);
	if ($comment) {	
	    $comment =~ s/\)//;
# remove the  /FTId=VAR_014497 information
	    $comment =~ s/\s+\/FTId=.*$//;
	}
	else {$comment = "";}
	next if ($comment =~ /MISSING/);
	my ($vfrom, $vto) = ($aa_res =~ m/(\w)\s*->\s*(\w)/);
	if ($vto) {
	  $comment = '' unless $comment;
	  $value = $vto;
	  push @sites, [$pos, $annot_types->{$label}, $value, $comment];
	}
      } elsif ($label =~ m/MUTAGEN/) {
	my ($aa_res, $comment) = split(/: /,$value);
	next if ($comment =~ /MISSING/);
	my ($vfrom, $vto) = split(/\->/,$aa_res);
	if ($vto) {
	  my @vto_list = split(/,/,$vto);
	  $value = $vto;
	  for my $val ( @vto_list) {
	    push @sites, [$pos, $annot_types->{$label}, $val, "Mutagen: $comment"];
	  }
	}
      } elsif ($label =~ m/DOMAIN/ || $label =~ m/REPEAT/) {
	$value = domain_name($label,$value);
	push @feats2, [$pos, "-", $end, $value];

      } elsif ($label =~ m/SSTR/) {
	next if $value =~ m/TURN/;
	push @feats2, [$pos, "-", $end, $value];
      }
      else {
#	print join("\t",($pos, $annot_types->{$label})),"\n";
#	print join("\t",($pos, $annot_types->{$label}, "-", "$label: $value")),"\n";
	push @sites, [$pos, $annot_types->{$label}, "-", "$label: $value"];
      }
    }
  }

  # ensure that domains do not overlap
  for (my $i=1; $i < scalar(@feats2); $i++) {
    my $diff = $feats2[$i-1]->[2] - $feats2[$i]->[0];
    if ($diff >= 0) {
      $feats2[$i-1]->[2] = $feats2[$i]->[0]+ int($diff/2);
      $feats2[$i]->[0] = $feats2[$i-1]->[2] + 1;
    }
  }

  my @n_feats2 = ();

  if ($neg_doms) {
    my $last_end = 0;
    for my $feat ( @feats2 ) {
      if ($feat->[0] - $last_end > $min_nodom) {
	push @n_feats2, [$last_end+1, "-", $feat->[0]-1, "NODOM"];
      }
      $last_end = $feat->[2];
    }
    if ($seq_len - $last_end > $min_nodom) {
      push @n_feats2, [$last_end+1, "-", $seq_len, "NODOM"];
    }
  }

  my @feats = ();
  for my $feat (@feats2, @n_feats2) {
    push @feats, [$feat->[0], '[', '-', $feat->[-1] ];
    push @feats, [$feat->[2], ']', '-', ""];
  }

  @feats = sort { $a->[0] <=> $b->[0] } (@sites, @feats);

  return \@feats;
}

sub get_lav_annots {
  my ($annot_types, $get_annots_sql, $seq_len) = @_;

  my ($pos, $end, $label, $value, $comment);

  my @feats = ();

  my %annot = ();
  while (($acc, $pos, $end, $label, $value) = $get_annots_sql->fetchrow_array()) {
    next unless ($label =~ m/^DOMAIN/ || $label =~ m/^REPEAT/);
    $value = domain_name($label,$value);
    push @feats, [$pos, $end, $value];
  }

  return \@feats;
}

# domain name takes a uniprot domain label, removes comments ( ;
# truncated) and numbers and returns a canonical form. Thus:
# Cortactin 6.
# Cortactin 7; truncated.
# becomes "Cortactin"
#

sub domain_name {

  my ($label, $value) = @_;

  if ($label =~ /DOMAIN|REPEAT/) {
    unless ($pfam26) {
      $value =~ s/;.*$//;
      $value =~ s/\.\s*$//;
      $value =~ s/\s+\d+$//;
    }
    if (!defined($domains{$value})) {
      $domain_cnt++;
      $domains{$value} = $domain_cnt;
    }
    return $value;
  }
  else {
    return $value;
  }
}



__END__

=pod

=head1 NAME

ann_feats2l.pl

=head1 SYNOPSIS

 ann_feats2l.pl --no_doms --no_feats --lav 'sp|P09488|GSTM1_NUMAN' | accession.file

=head1 OPTIONS

 -h	short help
 --help include description
 --no-doms  do not show domain boundaries (domains are always shown with --lav)
 --no-feats do not show feature (variants, active sites, phospho-sites)
 --lav  produce lav2plt.pl annotation format, only show domains/repeats
 --neg-doms,  -- report domains between annotated domains as NODOM
                 (also --neg, --neg_doms)
 --min_nodom=10  minimum non-domain length to produce NODOM
 --host, --user, --password, --port --db -- info for mysql database

=head1 DESCRIPTION

C<ann_feats2l.pl> extracts feature, domain, and repeat information from
a msyql database (default name, uniprot) built by parsing the
uniprot_sprot.dat and uniprot_trembl.dat feature tables.  Given a
command line argument that contains a sequence accession (P09488) or
identifier (GSTM1_HUMAN), the program looks up the features available
for that sequence and returns them in a tab-delimited format:

>sp|P09488|GSTM1_HUMAN
2	[	-	GST N-terminal :1
7	V	F	Mutagen: Reduces catalytic activity 100- fold.
23	*	-	MOD_RES: Phosphotyrosine (By similarity).
33	*	-	MOD_RES: Phosphotyrosine (By similarity).
34	*	-	MOD_RES: Phosphothreonine (By similarity).
88	]	-	
90	[	-	GST C-terminal :2
108	V	Q	Mutagen: Reduces catalytic activity by half.
108	V	S	Mutagen: Changes the properties of the enzyme toward some substrates.
109	V	I	Mutagen: Reduces catalytic activity by half.
116	#	-	BINDING: Substrate.
116	V	A	Mutagen: Reduces catalytic activity 10-fold.
116	V	F	Mutagen: Slight increase of catalytic activity.
173	V	N	in allele GSTM1B; dbSNP:rs1065411.
208	]	-	
210	V	T	in dbSNP:rs449856.

If features are provided, then a legend of feature symbols is provided
as well:

 =*:phosphorylation
 ==:active site
 =@:site
 =^:binding
 =!:metal binding

If the C<--lav> option is specified, domain and repeat features are
presented in a different format for the C<lav2plt.pl> program:

  >sp|P09488|GSTM1_HUMAN
  2	88	GST N-terminal.
  90	208	GST C-terminal.

C<ann_feats2l.pl> is designed to be used by the B<FASTA> programs with
the C<-V \!ann_feats2l.pl> option.  It can also be used with the lav2plt.pl
program with the C<--xA "\!ann_feats2l.pl --lav"> or C<--yA "\!ann_feats2l.pl --lav"> options.

=head1 AUTHOR

William R. Pearson, wrp@virginia.edu

=cut
