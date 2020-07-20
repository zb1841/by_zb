#!/usr/bin/perl
#计算2个句子的句型相似度
use Encode;
use POSIX;

# Create CGI requests from HTTP::Requests, specifically the sort of
# requests that come from POE::Component::Server::HTTP.
use warnings;
use strict;
use Smart::Comments;

#use Text::Similarity::Overlaps;
use POE;
use POE::Component::Server::HTTP;
use CGI ":standard";
use URI::Escape;

#urlencode
use HTML::Entities;

# Start an HTTP server.  Run it until it's done, typically forever,
# and then exit the program.
POE::Component::Server::HTTP->new(
    Port           => 19813,
    ContentHandler => {
        '/'       => \&root_handler,
        '/post/'  => \&post_handler,
        '/post2/' => \&post_handler2,
    }
);
POE::Kernel->run();
exit 0;

# Handle root-level requests.  Populate the HTTP response with a CGI
# form.
sub root_handler {
    my ( $request, $response ) = @_;
    $response->code(RC_OK);
   my $q;
    if ( $request->method() eq 'POST' ) {
        $q = new CGI( $request->content );
    }
    else {
        $request->uri() =~ /\?(.+$)/;
        if ( defined($1) ) {
            $q = new CGI($1);
        }
        else {
            $q = new CGI;
        }
    }
    my $um      = $q->param("u");
    my $content = `cat /mnt/sdb/shell2/$um/ME_file`;
    $response->content(

        #start_html("Sample Form")
        "<html>
<head><meta http-equiv=Content-Type content=\"text/html; charset=utf-8\">"

#                ." <html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"zh-CN\" xml:lang=\"zh-CN.gb2312\">                <head>"
          . start_form(
            -method => "post",
            -action => "/post/",

            # -enctype => "multipart/form-data",
            -enctype => "application/x-www-form-urlencoded;charset=utf-8",
          )
          . br()
          . "训练语句和答案 "
          . br() . "
<TEXTAREA NAME=\"m\" COLS=\"80\" ROWS=\"10\">
$content
</TEXTAREA>
         . br() . "用户名：<TEXTAREA NAME=\"d\" COLS=\"10\" ROWS=\"1\">
$um</TEXTAREA>
"

          #   . "测试语句: "
          #     . br()
          #     ."
          #     <TEXTAREA NAME=\"d\" COLS=\"80\" ROWS=\"10\">
          #小明感觉有点热</TEXTAREA>
          #      "
          . submit( "保存训练语料", "保存训练语料" )
          . end_form()
          . start_form(
            -method => "post",
            -action => "/post2/",

            # -enctype => "multipart/form-data",
            -enctype => "application/x-www-form-urlencoded;charset=utf-8",
          )
          . br()

          #. "训练语句和指令: "
          . br() . "
用户名：<TEXTAREA NAME=\"m\" COLS=\"10\" ROWS=\"1\">
$um</TEXTAREA>
"
          . br() . "测试语句: " . br() . "
<TEXTAREA NAME=\"d\" COLS=\"80\" ROWS=\"10\">
小明感觉有点热</TEXTAREA>
"
          . submit( "submit", "submit" ) . end_form()

          . end_html()
    );
    return RC_OK;
}

sub post_handler {
   my ( $request, $response ) = @_;

    # This code creates a CGI query.
    my $q;
    if ( $request->method() eq 'POST' ) {
        $q = new CGI( $request->content );
    }
    else {
        $request->uri() =~ /\?(.+$)/;
        if ( defined($1) ) {
            $q = new CGI($1);
        }
        else {
            $q = new CGI;
        }
    }

    # The rest of this handler displays the values encapsulated by the
    # object.
    $response->code(RC_OK);
    my @mall;

    my $am;
    my $dm;
    $am = $q->param("m");
    $dm = $q->param("d");
    $dm = decode_entities($dm);

    #chomp($dm);
    open( FD, ">/mnt/sdb/shell2/$dm/ME_file" );
    print FD $am;
    print "dm---------------/mnt/sdb/shell2/$dm/ME_file---\n";
    close FD;
    print "amdm $am $dm\n";

    $am = decode_entities($am);
    if ( !-e "/mnt/sdb/shell2/$dm" ) {
        my $c = `mkdir /mnt/sdb/shell2/$dm`;
   }

    #$am=~s/。|;|/\n/gis;
    #$dm=~s/。|;|/\n/gis;
    my $rand;
    $rand = rand();
    @mall = split( "\n", $am );
    my $inn = scalar(@mall);
    my @ball;
    my $kinn = 0;

    #@ball=split("\n",$dm);
    open( FD, ">/tmp/$rand.name" );
    foreach my $j (@mall) {
        if ( $j =~ /^\#/ ) {
            next;
        }
        $kinn++;
        print FD $j, "\n";
    }
    $kinn = ceil( $kinn / 50 ) + 1;
    print "$kinn 分为k类 $kinn\n";
    close FD;
    my $run = `awk {'print \$1'} /tmp/$rand.name > /tmp/$rand.clu`;
    my $run2 =
      `/mnt/sdb/shell2/client_k4.pl /tmp/$rand.clu $kinn > /tmp/$rand.kinfo`;
    system("dos2unix /tmp/$rand.kinfo");
    system("dos2unix /tmp/$rand.name");
    open( FDina,   "/tmp/$rand.kinfo" );
    open( FDtotal, ">//mnt/sdb/shell2/$dm/train.total" );
    my $nowk = 0;
    my $khash;
    open( ORG, "/tmp/$rand.name" );

    while (<ORG>) {
        my $line = $_;
        chomp($line);
       if ( $line =~ /(.*?) (.*)/ ) {
            $khash->{$1} = $2;
        }

    }
    close ORG;
    while (<FDina>) {
        my $line  = $_;
        my $linel = length($line);
        if ( ( $line =~ /^\d+\t\d+.*/ ) || ( $line =~ /^\d+\n/ ) ) {
            close FDnok;
            $nowk++;
            if ( !-e "/mnt/sdb/shell2/$dm/$nowk" ) {
                mkdir("/mnt/sdb/shell2/$dm/$nowk");
                system("cp  TrainFeature /mnt/sdb/shell2/$dm/$nowk");
            }
            else {

            }
            open( FDnok, ">/mnt/sdb/shell2/$dm/$nowk/$nowk" );
            print "/tmp/$rand.kinfo.$nowk \n";
            next;

        }
        elsif ( $line =~ /^------/ ) {
            close FDnok;

            close FDtotal;
            last;
        }
        elsif ( $linel >= 2 ) {
            chomp($line);
            print FDnok "$line $khash->{$line}\n";
            print FDtotal "$line $nowk\n";
        }
    }

    #foreach my $j (@ball)
    #{
    #print FD $j,"\n";
    #}
    #close FD;
    my $res;
    print "start\n";

    $res =
      `/mnt/sdb/shell2/txt2me_train_mu.pl /mnt/sdb/shell2/$dm/train.total $dm`;
    for ( 0 .. $nowk - 1 ) {
        my $kkk = $_ + 1;
        $res =
`/mnt/sdb/shell2/txt2me_train_mu.pl /mnt/sdb/shell2/$dm/$kkk/$kkk $dm/$kkk `;

    }
    print "ok\n";
    unlink("/tmp/$rand.name");

    #           unlink("/tmp/$rand.q");
    $response->content("$res--");
    return RC_OK;
}

sub post_handler2 {
    my ( $request, $response ) = @_;

    # This code creates a CGI query.
    my $q;
    if ( $request->method() eq 'POST' ) {
        $q = new CGI( $request->content );
    }
    else {
        $request->uri() =~ /\?(.+$)/;                                                                                                           
       if ( defined($1) ) {
            $q = new CGI($1);
        }
        else {
            $q = new CGI;
        }
    }

    # The rest of this handler displays the values encapsulated by the
    # object.
    $response->code(RC_OK);
    my @mall;

    my $am;
    my $dm;
    $am = $q->param("m");
    $dm = $q->param("d");
    print " 22222222222222222222222222amdm $am $dm\n";

    $am = decode_entities($am);
    $dm = decode_entities($dm);

    #$am=~s/。|;|/\n/gis;
    #$dm=~s/。|;|/\n/gis;
    #@mall=split("\n",$am);
    my @ball;
    @ball = split( "\n", $dm );
    my $rand;
    $rand = rand();

    #open(FD,">/tmp/$rand.name");
    #foreach my $j (@mall)
    #{
    #print FD $j,"\n";
    #}
    #close FD;
    my $res;
    my $res2 = "<html>
<head><meta http-equiv=Content-Type content=\"text/html; charset=utf-8\">";
    foreach my $j (@ball) {
        open( FD, ">/tmp/$rand.q" );
        print FD $j, "\n";
        close FD;
        if ( !-e "/mnt/sdb/shell2/$am" ) {
            my $c = `mkdir /mnt/sdb/shell2/$am`;
        }

#$res=`/mnt/sdb/shell2/btest.pl  /tmp/$rand.q /mnt/sdb/shell2/$am/__MAXENT_MAPPING.model /mnt/sdb/shell2/$am/__MAXENT_PARAMS.model`;
#print "/mnt/sdb/shell2/btest.pl  /tmp/$rand.q /mnt/sdb/shell2/$am/__MAXENT_MAPPING.model /mnt/sdb/shell2/$am/__MAXENT_PARAMS.model\n";
### @ball
#my @ares=split("\n",$res);
#for (0 .. 1)
#{
#if($ares[$_]=~/(\d+) .*/)
#{
#       my $us=$1;
#$res2.=`/mnt/sdb/shell2/btest.pl  /tmp/$rand.q /mnt/sdb/shell2/$am/$us/__MAXENT_MAPPING.model /mnt/sdb/shell2/$am/$us/__MAXENT_PARAMS.model`;
#}
        $res2 .= "$j\n";
        print "/mnt/sdb/shell2/btest2.pl  /tmp/$rand.q  $am";
        $res2 .= `/mnt/sdb/shell2/btest2.pl  /tmp/$rand.q  $am`;

        #$res2 .= `/mnt/sdb/shell2/btest2.pl_bk  /tmp/$rand.q  $am`;
### $res2
        #}
        $res2 .= "---------\n";
    }

#print "/mnt/sdb/shell2/btest.pl  /tmp/$rand.q /mnt/sdb/shell2/$am/__MAXENT_MAPPING.model /mnt/sdb/shell2/$am/__MAXENT_PARAMS.model\n";
### $res
    #$res=`/mnt/sdb/shell2//txt2me_train_mu_pre.pl  /tmp/$rand.q $am`;
    #           unlink("/tmp/$rand.name");
    #           unlink("/tmp/$rand.q");
    $res2 .= "</body>
</html>";
    $response->content("$res2--");
    return RC_OK;
}


