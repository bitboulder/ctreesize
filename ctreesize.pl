#!/usr/bin/perl

use strict;
use File::Basename;
use Cwd 'realpath';
use Term::ReadLine;

my $term = new Term::ReadLine basename($0);
my %info=();
if(@ARGV){ &main(@ARGV); }else{ &main("."); }

sub main {
	my @dir=@_;
	while(1){
		my $base="";
		@dir=&xrealpath(@dir);
		if(@dir==1){
			$base=$dir[0];
			@dir=&readdir($dir[0]);
		}
		my $xsi=&getinfo(@dir);
		my $in=&out($xsi,$base,@dir);
		last if "quit"eq$in;
		if(""ne$in){ @dir=($in); }
		elsif(""ne$base){ @dir=($base); }
	}
}

sub xrealpath {
	my @fn=@_;
	foreach my $fn (@fn){ $fn=realpath($fn); }
	return @fn;
}

sub readdir {
	(my $dn)=@_;
	opendir DIR,$dn;
	my @fn=();
	foreach my $fn (readdir DIR){
		next if $fn=~/^\.+$/;
		push @fn,$dn."/".$fn;
	}
	closedir DIR;
	return @fn;
}

sub getinfo {
	my $xsi=0;
	foreach my $fn (@_){
		next if exists $info{$fn};
		my $v=`du -s $fn`;
		$xsi+=$v;
		$v=~/ .*/;
		$info{$fn}->{size}=$v;
		$info{$fn}->{typ}="";
		$info{$fn}->{typ}.="l" if -l $fn;
		$info{$fn}->{typ}.="d" if -d $fn;
	}
	return $xsi;
}

sub out {
	(my $xsi,my $base,my @dir)=@_;
	@dir=reverse sort {$info{$a}->{size}<=>$info{$b}->{size}} @dir;
	my $id=0;
	my %in=();
	open LD,@dir>20?"| less -M -S":">&STDOUT";
	if(""ne$base){
		print LD "####### $base ########\n";
		unshift @dir,$base."/..";
	}else{
		print LD "####### MISC ########\n";
	}
	foreach my $fn (@dir){
		my $i=$info{$fn};
		my $t=$i->{typ};
		my $id1="";
		my $ofn=""eq$base?$fn:basename($fn);
		if($t=~/d/ || $fn=~/\/\.\.$/){
			$t.="d" if $t!~/d/;
			$id1=++$id;
			#$in{$id1}=$fn;
			$in{$ofn}=$fn;
		}
		#printf LD "%3s %5s %5s %2s %s\n",$id1,
		printf LD "%5s %5s %2s %s\n",
			exists $info{$fn}?&fmtprc($i->{size},$xsi):"--",
			exists $info{$fn}?&fmtsi($i->{size}):"--",
			$t,$ofn;
	}
	close LD;
	my $in=$term->readline("Input folder ID/name (\"\"->remain, q->quit): ");
	return $in{$in} if exists $in{$in};
	return "quit" if $in=~/quit|exit/i || "0"eq$in || "q"eq$in;
	return "";
}

sub fmtsi {
	(my $v)=@_;
	my @ext=("k","M","G");
	while($v>=999){ $v/=1024; shift @ext; }
	my $c= $v>=20 ? 0 : $v>=2 ? 1 : 2;
	return sprintf "%.".$c."f%s",$v,$ext[0];
}

sub fmtprc {
	(my $v,my $x)=@_;
	$v= $x ? $v/$x*100 : 0;
	my $c= $v>=20 ? 0 : $v>=2 ? 1 : 2;
	return sprintf "%.".$c."f%%",$v;
}
