#!/usr/bin/perl

use strict;
use warnings;

Main();

# Main()
# opens pages.txt file of format:
# STYLEPATH
# PARENTDIR/PARENTDIR/PARENTDIR...
# PAGE
# PAGE
# PAGE
# ...
# creates html file for each page and an index page
sub Main {
	my @pages = ();
	my $html;
	my $string;
	my $stylePath;

	open(my $fileHandle, 'pages.txt') or die "Failed to open pages.txt";
	$stylePath = substr(<$fileHandle>, 0, -1);
	<$fileHandle>;
	while (<$fileHandle>) {
		my $i = $_;
		$string = substr($i, 0, -1);
		if (substr($string, -1, 1) ne '/') {
			push(@pages, $string);
		}
	}
	close($fileHandle);
	open($fileHandle, ">index.html") or die "Failed to open index.html";
	$html = MakeHtml('index', $stylePath);
	print $fileHandle $html;
	close($fileHandle);
	foreach my $i (@pages) {
		$html = MakeHtml($i, $stylePath);
		open($fileHandle, ">$i.html") or die "Failed to open $i.html";
		print $fileHandle $html;
		close($fileHandle);
	}
}

# MakeHtml ( $title, $stylePath )
# returns string of html code containing entire page
sub MakeHtml {
	my $title = $_[0];
	my $stylePath = $_[1];
	my $htmlString;
	my @head = @{MakeHead($title, $stylePath)};
	my @sidebarArray = @{MakeSidebar('pages.txt', $title)};
	my @mainArray = @{MakeMain("$title.txt")};
	my @bodyArray = ();
	my @htmlArray = ();

	push(@bodyArray, @sidebarArray);
	push(@bodyArray, @mainArray);
	MakeDiv(\@bodyArray, 'body');
	push(@htmlArray, @head);
	push(@htmlArray, @bodyArray);
	MakeDiv(\@htmlArray, 'html');
	unshift(@htmlArray, '<!DOCTYPE html>');
	$htmlString = join("\n", @htmlArray);

	return $htmlString;
}

# PrintStringArray ( $stringArrayRef );
# prints each string in array delimited by newlines for debugging purposes
sub PrintStringArray {
	my $stringArrayRef = $_[0];

	foreach my $i (@$stringArrayRef) {
		print "$i\n";
	}
}

# MakeHead ($title, $stylePath)
# makes html head
sub MakeHead {
	my $title = $_[0];
	my $stylePath = $_[1];
	my @stringArray = ();

	push(@stringArray, "<meta charset='utf-8'>");
	push(@stringArray, "<link rel='stylesheet' href='$stylePath'>");
	push(@stringArray, "<title>$title</title>");
	MakeDiv(\@stringArray, 'head');
	return \@stringArray;
}

# MakeSidebar ( $filename, $active );
# generates html for sidebar from list of page names in $filename and assigns
# 'active' class to link to page of name $active
sub MakeSidebar {
	my $fileName = $_[0];
	my $active = $_[1];
	my $parentUrl = './';
	my @stringArray = ();
	my @parents = ();

	open (my $fileHandle, $fileName) or die "Failed to open $fileName";
	<$fileHandle>;
	@parents = split('/', substr(<$fileHandle>, 0, -1));
	foreach my $i (@parents) {
		$i .= '/';
	}
	while (<$fileHandle>) {
		my $i = $_;
		$i = substr($i, 0, -1);
		push(@stringArray, $i);
	}
	close($fileHandle);
	foreach my $i (@stringArray) {
		if ($i eq $active) {
			MakeTag(\$i, 'a', "href='$i' class='active'");
		} else {
			MakeTag(\$i, 'a', "href='$i'");
		}
	}
	MakeUl(\@stringArray);
	@parents = reverse(@parents);
	foreach my $i (@parents) {
		MakeTag(\$i, 'a', "href='$parentUrl'");
		$parentUrl .= '../';
	}
	if ($active eq 'index') {
		$parents[0] =~ s/<a/<a class='active'/;
	}
	foreach my $i (@parents) {
		MakeTag(\$i, 'li');
		MakeDiv(\@stringArray, 'li');
		unshift (@stringArray, $i);
		MakeDiv(\@stringArray, 'ul');
	}
	MakeDiv(\@stringArray, 'div', 'class="sidebar"');
	return \@stringArray;
}

# MakeMain ($fileName);
# makes main body of text from text file
sub MakeMain {
	my $fileName = $_[0];
	my @stringArray = ();

	open(my $fileHandle, $fileName) or die "Failed to open $fileName";
	while(<$fileHandle>) {
		my $i = $_;
		push(@stringArray, substr($i, 0, -1));
	}
	close($fileHandle);
	MakeDiv(\@stringArray, 'div', 'class="main"');
	return \@stringArray;
}

# MakeDiv ( $stringArrayRef, $tag, $args );
# indents and encloses referenced array in a div
sub MakeDiv {
	my $n = scalar(@_);
	my $stringArrayRef = $_[0];
	my $tag = $_[1];
	my $args;

	foreach my $i (@$stringArrayRef) {
		$i = "\t" . $i;
	}
	if ($n > 2) { 
		$args = $_[2];
		unshift(@$stringArrayRef, "<$tag $args>");
	} elsif ($n == 2) {
		unshift(@$stringArrayRef, "<$tag>");
	}
	push(@$stringArrayRef, "</$tag>");
}

# MakeTag ( $text, $tag, $args );
# encloses referenced string in tag
sub MakeTag {
	my $n = scalar(@_);
	my $stringRef = $_[0];
	my $tag = $_[1];
	my $args;

	if ($n > 2) {
		$args = $_[2];
		$$stringRef = "<$tag $args>$$stringRef</$tag>";
	} elsif ($n == 2) {
		$$stringRef = "<$tag>$$stringRef</$tag>";
	}
}

# MakeUl ( $stringArrayRef );
# encloses each string in $stringArrayRef in <li> tag and encloses entire array
# in <ul> div
sub MakeUl {
	my $stringArrayRef = $_[0];

	foreach my $i (@$stringArrayRef) {
		MakeTag(\$i, 'li')
	}
	MakeDiv($stringArrayRef, 'ul');
}
