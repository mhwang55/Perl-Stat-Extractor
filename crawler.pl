#!/usr/bin/perl
# x.x means version.iteration
# ex. 4.2 means version 4 iteration 2

# this program does the following:
# takes all the linux versions and iterations released and gets the version and
# iteration number, number of iterations of each version, total size of all
# iterations, avg size of each iteration, date of release of first iteration,
# date of release of last version, and the number of days between release of
# first and last iterations

# note: to run this script and get the data set, run using the command
# ./crawler.pl > *.txt
# where * is your file name

use strict;
use warnings;
use Date::Parse;

# get folders and html files from web
# comment this line out if already have the folders necessary
#*************************************************************#
#`wget -c -r -l 1 --accept-regex "v[1-4]\." https://www.kernel.org/pub/linux/kernel/`;
#*************************************************************#

# each element of @lst has format filepath:number of lines
my @lst = split /\n/, `grep -r -ci "href=\"[^\/]*\"" */*/*/*/v*/*`;
my %versionPaths = ();
my %versions = ();
my %versionIter = ();
my %versionTimes = ();
my %versionSizes = ();
my %versionStats = ();
my $num;
my $link;

for my $a (@lst)
{
  $a =~ /(.*):(.*)/;
  $link=$1;			# get filepath
  $num=$2;			# get number of lines
  $1 =~ /(v.*?)\//;		# get version.iteration
  $versionPaths{$1}=$link;	# key = version.iteration; value = filepath
  $versions{$1}=$num;		# key = version.iteration;
				# value = number of lines
}

my @data;
my $unsplit;

# loops through all the html files to get each complete linux iteration
for my $key (keys %versionPaths)
{
  # will need to change this filepath to wherever you save this script
  my $fileName="/home/student/proj/webcrawler/$versionPaths{$key}";

  open F, "<$fileName" || die "can't open $fileName\n";
  while(<F>)
  {
    # checks each html file for .tar.gz, signaling a complete linux iteration
    if($_ =~ /linux.*?>.*?(\d\.\d{1,3}).*?\.tar\.gz<\/a>.*?(\d.*\d)/)
    {
      # $1 $2 where
      # $1 = x.y => $1 is version.iteration
      # $2 = day-month-year hour:min size
      # each list in @data has elements ver.iter, day-month-year, hour:min, size
      push(@data, [(split /\s+/, "$1 $2")]);
    }
  }

  close(F);
}

my $time;
my $timeFromEpoch;

for my $a (@data)
{
  $versionIter{@$a[0]}++; # increment for each new release of same iteration
  $versionSizes{@$a[0]}+=@$a[-1]; # for same iteration, add sizes

  # convert date to seconds from epoch (time not important)
  @$a[1] =~ s/-/ /g;
  $time = @$a[1]." ".@$a[2]." GMT";
  $timeFromEpoch = str2time($time);

  # create list of all seconds from epoch for each ver.iter
  if(exists $versionTimes{@$a[0]})
  {
    push(@{$versionTimes{@$a[0]}}, $timeFromEpoch);
  }
  else
  {
    $versionTimes{@$a[0]} = [$timeFromEpoch];
  }
}

my $avgSize;
my @sortedTimes = ();
my $temp;
my $temp2;
my $epochMax;
my $epochMin;
for my $key (keys %versionTimes) {
  # sort seconds from epoch list in min max fashion
  @sortedTimes = sort @{$versionTimes{$key}};

  # epochMax is maximum time from epoch for each ver.iter
  # epochMin is minimum time from epoch for each ver.iter
  if($sortedTimes[-1] > $sortedTimes[0])
  {
    $epochMax = $sortedTimes[-1];
    $epochMin = $sortedTimes[0];
  }
  else
  {
    $epochMin = $sortedTimes[-1];
    $epochMax = $sortedTimes[0];
  }
  my $distance = $epochMax - $epochMin;
  # get number of days between first release of ver.iter and last release
  $distance = int($distance / (24*3600));

  # scalar gmtime($var) returns
  # WeekDay Month MonthDay Hour:Min:Sec Year
  # ex. Sat Jan  1 00:00:00 2000
  # timezone is GMT
  my @min = split /\s+/, scalar gmtime $epochMin;
  my @max = split /\s+/, scalar gmtime $epochMax;

  # changing format to
  # MonthDay Month Year Hour:Min
  # ex. Jan  01 2000 00:00
  shift @min;
  $temp = shift @min;
  $temp2 = shift @min;
  unshift @min, $temp;
  $temp2 =~ s/^(\d)$/0$1/;
  unshift @min, $temp2;
  $temp = pop @min;
  push @min, $temp;
  $temp = pop @min;
  $temp2 = pop @min;
  push @min, $temp;
  $temp2 =~ s/^(.*):.*/$1/;
  push @min, $temp2;

  shift @max;
  $temp = shift @max;
  $temp2 = shift @max;
  unshift @max, $temp;
  $temp2 =~ s/^(\d)$/0$1/;
  unshift @max, $temp2;
  $temp = pop @max;
  push @max, $temp;
  $temp = pop @max;
  $temp2 = pop @max;
  push @max, $temp;
  $temp2 =~ s/^(.*):.*/$1/;
  push @max, $temp2;

  # create a string from arrays and hyphenate day, month, and year together
  my $min = join "-", @min;
  my $max = join "-", @max;
  $min =~ s/(.*)-/$1 /;
  $max =~ s/(.*)-/$1 /;
  $versionTimes{$key} = [$min, $max, $distance];
}

# create a hash of lists
# each list is formatted such that
# @list = (vNum, vIter, nIter, tSize, aSize, bDate, eDate, lTime)
# where
# vNum  is version number
# nIter is number of iterations in version
# tSize is total size of all iterations in bytes
# aSize is avg size of each version in bytes
# bDate is date first iteration of version was released
# eDate is date last iteration of version was released
# lTime is number of days between release of first and last iteration

for my $key (keys %versionTimes) {
  $avgSize=int($versionSizes{$key}/$versionIter{$key});
  my ($numIter, $ttlSize, $bDate, $eDate, $lTime) = ($versionIter{$key},
    $versionSizes{$key}, ${$versionTimes{$key}}[0], ${$versionTimes{$key}}[1],
    ${$versionTimes{$key}}[2]);

  $versionStats{$key} = [$numIter, $ttlSize, $avgSize, $bDate, $eDate, $lTime];
}

my @keys = ();
my @sortedKeys = ();

# sort versions numbers
# ex. 1.1, 1.10, 1.3, 1.2 => 1.1, 1.2, 1.3, 1.10
for my $key (keys %versionStats) {
  $key =~ s/(\d\.)(\d)$/${1}0$2/;
  push(@keys, $key);
}
@sortedKeys = sort @keys;
for(my $key=0; $key<@sortedKeys; $key++) {
  $sortedKeys[$key] =~ s/(\d\.)0(\d)$/$1$2/;
}

# textfile formatted such that columns are
# vNum; vIter; nIter; tSize; aSize; bDate; eDate; lTime
for my $key (@sortedKeys)
{
  print "$key;", join(";", @{$versionStats{$key}}), "\n"
}
