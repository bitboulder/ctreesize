#!/usr/bin/perl

use strict;
use File::Basename;
use Cwd 'realpath';
use Term::ReadLine;

my $term = new Term::ReadLine basename($0);
my %info=();
if(@ARGV){ &main(@ARGV); }else{ &main("."); }

sub main {
	my %dir=();
	if(@_[0]eq"-d"){
		shift @_;
		@{$dir{0}}=splice @_,0,int(@_/2);
		@{$dir{1}}=@_;
	}else{ @{$dir{0}}=@_; }
	while(1){
		my %base=();
		&xrealpath(values %dir);
		if(@{$dir{0}}==1 && (!exists $dir{1} || @{$dir{1}}==1)){
			foreach my $t (keys %dir){
				$base{$t}=$dir{$t}->[0];
				@{$dir{$t}}=&readdir($base{$t});
			}
		}
		&getinfo(values %dir);
		my @in=&out(\%base,\%dir);
		last if "[QUIT]"eq$in[0];
		if("[REFRESH]"eq$in[0]){ @in=(); %info=(); }
		if(@in){
			foreach my $t (keys %dir){ @{$dir{$t}}=($in[$t]); }
		}elsif(0<keys %base){
			foreach my $t (keys %dir){ @{$dir{$t}}=($base{$t}); }
		}
	}
}

sub arr2hsh {
	(my $hsh,my $val,my @arr)=@_;
	foreach my $key (@arr){ $hsh->{$key}=$val; }
}

sub xrealpath {
	foreach my $arr (@_){
		foreach my $fn (@{$arr}){ $fn=realpath($fn); }
	}
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
	foreach my $arr (@_){
		foreach my $fn (@{$arr}){
			next if exists $info{$fn};
			my $v=`du -s $fn`;
			$v=~/ .*/;
			$info{$fn}->{size}=$v;
			$info{$fn}->{typ}="";
			$info{$fn}->{typ}.="l" if -l $fn;
			$info{$fn}->{typ}.="d" if -d $fn;
		}
	}
}

sub out {
	(my $base,my $dir)=@_;
	my @out;
	if(exists $dir->{1}){
		my @out0=&dir2out($base->{0},@{$dir->{0}});
		my @out1=&dir2out($base->{1},@{$dir->{1}});
		@out=&outdiff(\@out0,\@out1);
	}else{
		@out=&dir2out($base->{0},@{$dir->{0}});
	}
	my $xsi=0; foreach my $h (@out){ $xsi+=abs($h->{val}); }
	@out=reverse sort {abs($a->{val})<=>abs($b->{val})} @out;
	@out=splice @out,0,10;
	my %in=();
	open LD,@out>20?"| less -M -S":">&STDOUT";
	unshift @out,&headout($base);
	foreach my $h (@out){
		$in{$h->{name}}=$h->{fn} if $h->{typ}=~/d/;
		if(exists $dir->{1}){
			printf LD "%5s %6s %5s>%5s %4s %s\n",
				exists $h->{val}?&fmtprc($h->{val},$xsi):"--",
				exists $h->{val}?&fmtsi($h->{val}):"--",
				exists $h->{size}->{0}?&fmtsi($h->{size}->{0}):"--",
				exists $h->{size}->{1}?&fmtsi($h->{size}->{1}):"--",
				$h->{typ},$h->{name};
		}else{
			printf LD "%5s %5s %2s %s\n",
				exists $h->{val}?&fmtprc($h->{val},$xsi):"--",
				exists $h->{val}?&fmtsi($h->{val}):"--",
				$h->{typ},$h->{name};
		}
	}
	close LD;
	my $in=$term->readline("Input folder ID/name (\"\"->remain, r->refresh, q->quit): ");
	return @{$in{$in}} if exists $in{$in};
	return "[QUIT]" if $in=~/quit|exit/i || "0"eq$in || "q"eq$in;
	return "[REFRESH]" if $in=~/refresh/i || "r"eq$in;
	return &findinpat($in,\%in);
}

sub dir2out {
	(my $base,my @dir)=@_;
	my @out=();
	foreach my $fn (@dir){
		@{$out[@out]->{fn}}=($fn);
		$out[@out-1]->{name}=""eq$base?$fn:basename($fn);
		if(exists $info{$fn}){
			$out[@out-1]->{val}=$info{$fn}->{size};
			$out[@out-1]->{typ}=$info{$fn}->{typ};
			$out[@out-1]->{i}=$info{$fn};
		}
	}
	return @out;
}

sub outdiff {
	(my $out0,my $out1)=@_;
	my %ref=();
	foreach my $h (@{$out0}){ $ref{$h->{name}}->{0}=$h; }
	foreach my $h (@{$out1}){ $ref{$h->{name}}->{1}=$h; }
	my @out=();
	foreach my $name (keys %ref){
		my $r=$ref{$name};
		my $r0=$r->{0};
		my $r1=$r->{1};
		my %o=();
		@{$o{fn}}=($r0->{fn},$r1->{fn});
		$o{name}=$name;
		$o{val}=$r1->{val}-$r0->{val};
		$o{typ}=(exists $r->{0}?$r0->{typ}:"#").">".(exists $r->{1}?$r1->{typ}:"#");
		$o{size}->{0}=$r0->{val} if exists $r->{0};
		$o{size}->{1}=$r1->{val} if exists $r->{1};
		push @out,\%o;
	}
	return @out;
}

sub headout {
	(my $base)=@_;
	if(0!=keys %{$base}){
		my @base=(); foreach(sort {$a<=>$b} keys %{$base}){ push @base,$base->{$_}; }
		print LD "####### ".(join " > ",@base)." ########\n";
		foreach(@base){ $_.="/.."; } # TODO: history
		my %add=(fn=>\@base,name=>"..",typ=>"d");
		return (\%add);
	}else{
		print LD "####### MISC ########\n";
		return ();
	}
}

sub findinpat {
	(my $in,my $hsh)=@_;
	my $found="";
	foreach my $name (keys %{$hsh}){
		next if $name!~/$in/;
		return () if ""ne$found;
		$found=$name;
	}
	return @{$hsh->{$found}} if ""ne$found;
	return ();
}

sub fmtsi {
	(my $v)=@_;
	my @ext=("k","M","G");
	while(abs($v)>=999){ $v/=1024; shift @ext; }
	my $c= abs($v)>=20 ? 0 : abs($v)>=2 ? 1 : 2;
	return sprintf "%.".$c."f%s",$v,$ext[0];
}

sub fmtprc {
	(my $v,my $x)=@_;
	$v= $x ? abs($v)/$x*100 : 0;
	my $c= $v>=20 ? 0 : $v>=2 ? 1 : 2;
	return sprintf "%.".$c."f%%",$v;
}
