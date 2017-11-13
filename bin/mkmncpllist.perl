#!/usr/local/bin/perl

use strict;
use utf8;

use Encode;
use Encode::JP::H2Z;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $FILE_POSTAL = './in/KEN_ALL.CSV';
my $FILE_SOURCE_CTV = './in/source-ctv.txt';
my $FILE_SOURCE_W = './in/source-w.txt';
my $ZENKAKU = 0;

sub usage {
  print STDERR "$0 -h | [-Z|-H] [-p <postal>] [-s <source ctv> <source ward>]\n";
}

# analyzes arguments
my @argv = analyze_arguments();

if( @argv > 0 ) {
  usage();
  die "$0: unnecessary filename supplied.";
}

# main
my $frompostal = {};
read_postal($FILE_POSTAL, $frompostal);
my $out_mncpl = [];
my $out_pref = [];
process_ctv($FILE_SOURCE_CTV, $frompostal, $out_mncpl, $out_pref);
process_ward($FILE_SOURCE_W, $out_mncpl);

@$out_mncpl = sort { $$a[0] <=> $$b[0] } @$out_mncpl;

foreach my $row ( @$out_mncpl ) {
  if( $ZENKAKU ) {
    for( my $n = 4; $n <= 6; $n++ ) {
      $$row[$n] = to_zenkaku($$row[$n]);
    }
  }
  print join("\t", @$row),"\n";
}

#
# subs
#
sub analyze_arguments {
  my @argv = ();
  my $noopt = 0;
  for( my $n = 0; $n < @ARGV; $n++ ) {
    my $flag = 0;
    my $arg = $ARGV[$n];
    if( !$noopt ) {
      if( $arg eq '--' ) {
        $flag = 1;
        $noopt = 1;
      }
      elsif( $arg eq '-h' ) {
        $flag = 1;
        usage();
        exit;
      }
      elsif( $arg eq '-Z' ) {
        $flag = 1;
        $ZENKAKU = 1;
      }
      elsif( $arg eq '-H' ) {
        $flag = 1;
        $ZENKAKU = 0;
      }
      elsif( $arg eq '-p' ) {
        $flag = 1;
        if( $n + 1 < @ARGV ) {
          $FILE_POSTAL = $ARGV[$n+1];
        }
        $n++;
      }
      elsif( $arg eq '-s' ) {
        $flag = 1;
        if( $n + 1 < @ARGV ) {
          $FILE_SOURCE_CTV = $ARGV[$n+1];
        }
        if( $n + 2 < @ARGV ) {
          $FILE_SOURCE_W = $ARGV[$n+2];
        }
        $n++;
      }
    }
    if( !$flag ) {
      push(@argv, $arg);
    }
  }
  @argv;
}

sub read_postal {
  my($file, $frompostal) = @_;
  my $fr;
  my @in_out_map = (0, 6, 7, 4);
  open($fr, '<:encoding(cp932)', $file) || die "$file: $!";
  while(<$fr>) {
    if( $_ =~ /^[0-9]{5}.*$/ ) {
      chomp;
      my @arr_in = split(/,/);
      my $arr_out = [];
      my $code = $arr_in[0];
      for( my $n = 0; $n < @in_out_map; $n++ ) {
        ($$arr_out[$n] = $arr_in[$in_out_map[$n]]) =~ s/^\"(.*)\"$/\1/;
      }
      if( !$$frompostal{$code} ) {
        $$frompostal{$code} = $arr_out;
      }
    }
  }
  close($fr);
}

sub process_ctv {
  my($file, $frompostal, $out_mncpl, $out_pref) = @_;
  my $line = 0;
  open(my $fr, '<:encoding(cp932)', $file) || die "$file: $!";
  while(<$fr>) {
    $line++;
    if( $_ =~ /^[0-9]{6}.*$/ ) {
      chomp;
      my($mcode,$pname,$mname,$pkana,$mkana) = split(/\t/);
      $mcode =~ s/^([0-9]{5}).*$/\1/;
      # pcode
      (my $pcode = $mcode) =~ s/^([0-9]{2}).*$/\1/;
      $pcode = $pcode * 1;
      if( !$$out_pref[$pcode] ) {
        $$out_pref[$pcode] = [$pname, $pkana];
      }
      # mcode
      if( $mcode % 1000 == 0 ) {
      }
      elsif( $mcode =~ /^[0-9]{2}1[0-9]0$/ ) {
        #
      }
      elsif( !$$frompostal{$mcode} ) {
        print STDERR "${line}: $mcode is not found at frompostal.\n";
        print STDERR "\t\"$_\"\n";
      }
      else {
        my($p_mcode,$p_pname,$p_mname,$p_mkana) = @{$$frompostal{$mcode}};
        my($sun,$con,$cn2) = ('', '', '');
        my($sunk,$conk,$cn2k) = ('', '', '');
        if( $p_mname ne $mname ) {
          if( $p_mname =~ /$mname$/ ) {
            ($con = $p_mname) =~ s/$mname$//;
            ($conk = $p_mkana) =~ s/$mkana$//;
            $cn2 = $mname;
            $cn2k = $mkana;
          }
          elsif( ($p_mname =~ /^[^郡]+郡[^郡]+$/)
              && index($p_mkana,"ｸﾞﾝ") >= 0
              && index($p_mkana,"ｸﾞﾝ") == rindex($p_mkana,"ｸﾞﾝ") ) {
            ($con = $p_mname) =~ s/^([^郡]+郡)[^郡]+$/\1/;
            $cn2 = $mname;
            ($conk = $p_mkana) =~ s/^(.*ｸﾞﾝ).*$/\1/;
            ($cn2k = $p_mkana) =~ s/^.*ｸﾞﾝ(.*)$/\1/;
            print STDERR
              "${line}: mismatched, but estimated.\n",
              "  \"$p_mname\" -> \"$con\" \"$cn2\"\n",
              "  \"$p_mkana\" -> \"$conk\" \"$cn2k\"\n";
          }
          else {
            print STDERR
              "${line}: mismatched.\n",
              "  source: \"$_\"\n",
              "  frompostal: \"$p_mname\"\n";
          }
        }
        else {
          $con = $mname;
          $conk = $mkana;
        }
        push(@$out_mncpl, [$mcode,$sun,$con,$cn2,$sunk,$conk,$cn2k]);
      }
    }
  }
}

sub to_zenkaku {
  my($kana) = @_;
  # internal utf8 -> euc-jp
  my $encoded = Encode::encode('euc-jp', $kana);
  # zenkaku to hankaku
  Encode::JP::H2Z::h2z(\$encoded);
  # euc-jp -> internal utf8
  return Encode::decode("euc-jp", $encoded);
}

sub to_hankaku {
  my($kana) = @_;
  $kana =~ tr/あ-ん/ア-ン/;
  # internal utf8 -> euc-jp
  my $encoded = Encode::encode('euc-jp', $kana);
  # zenkaku to hankaku
  Encode::JP::H2Z::z2h(\$encoded);
  # euc-jp -> internal utf8
  return Encode::decode("euc-jp", $encoded);
}

sub process_ward {
  my($file, $out_mncpl) = @_;
  my $line = 0;
  open(my $fr, '<:encoding(cp932)', $file) || die "$file: $!";
  my @parent = ();
  while(<$fr>) {
    $line++;
    if( $_ =~ /^[0-9]{6}.*$/ ) {
      chomp;
      my($mcode,$mname,$mkana) = split(/\t/);
      $mcode =~ s/^([0-9]{5}).*$/\1/;
      $mkana = to_hankaku($mkana);
      if( $mname =~ /^.*市$/ ) {
        # city name
        @parent = ($mcode, $mname, $mkana);
      }
      else {
        my $parent_mname = $parent[1];
        my $parent_mkana = $parent[2];
        $mname =~ s/^$parent_mname(.*)$/\1/;
        $mkana =~ s/^$parent_mkana(.*)$/\1/;
        push(@$out_mncpl, [$mcode,'',$parent_mname, $mname,'',$parent_mkana, $mkana]);
      }
    }
  }
}
