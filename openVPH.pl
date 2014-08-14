#!/usr/bin/perl

use POE::Component::IRC;
use POE::Component::IRC::State;
use POE::Kernel;
use Data::Dumper;
use POE::Session;

use strict;

# Las variables para la conexion
my ($nickname)  = 'openvph';
my ($ircname)   = 'Soy un BOT hecho en Perl y soy mejor que ovejorock que usa Python';
my ($ircserver) = 'irc.freenode.net';
my ($port)      = 6667;
my ($channel)   = ("#prueba");
my ($todos);
my ($irc) = POE::Component::IRC->spawn
        (
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
        ) or die "Espernanque ! $!";

POE::Session->create( package_states => ['main' => [ qw(_default _start irc_001 irc_public irc_msg irc_nick irc_part irc_join irc_public irc_kick irc_353 ) ],],);

$poe_kernel->run();

exit 0;

# esto toma lo dicho en el canal y lo interpreta
sub irc_public
        {
        my $nick = (split /!/, $_[ARG0])[0];
        my $canal = $_[ARG1]->[0];
        my $msg = $_[ARG2];
        my $respuesta;
        my $comando;
        my $dent;
        # si se da un comando se emite una respuesta
        $comando = comandos ($nick, $canal, $msg);
        # si se nombra al bot se genera una respuesta
        $respuesta = reconocimiento($nick, $msg, $canal) if ( $msg =~ /$nickname/i);
        # guarda en el LOG lo que se dijo en el canal
        loguear($nick, $msg);
        # si hay una respuesta o un comando se escribe en el canal y se guarda en el LOG
        if ($comando)
                {
                $irc->yield( privmsg => $canal => $comando );
                loguear("====>", $comando);
                }
        else
                {
                $irc->yield( privmsg => $canal => $respuesta ) if ($respuesta);
                loguear("***$nickname", $respuesta) if ($respuesta);
                }
        }

sub irc_msg
        {
        my $nick = (split /!/, $_[ARG0])[0];
        my $msg = $_[ARG2];
        }
# textos que el bot reconoce como comandos
sub comandos
        {
        my $salida;
        my $nick="";
        $nick= $_[0];
        my $canal = $_[1];
        my $msg = $_[2];

       # $salida ="JEFE lo llaman... o esta ocupado para atender triviliadidades de $nick :D" if ( $msg =~ /xombra/ or $msg =~ /jjedi/ or $msg =~ /Xombra/ );

        
        $salida ="$nick: Crees que porque hables en codigo nativo homosexual no te entiendo?" if ( $msg =~ /mmg/ );
        $salida ="Más lindo $nick asi me gusta, que hagan cosas por AWVEN sino se van partida de flojos" if ( $msg =~ /awven/ );
        $salida ="$nick: no grites por favor, me gusta que hablen de AWVEN, pero gritar es de ignorantes" if ( $msg =~ /AWVEN/ );
        $salida =extraer_frase($nick, $canal, $msg, "ubuntu", quien()) 
        if ( $msg =~ /ubuntu/ or $msg =~ /UBUNTU/ or /software libre/ or $msg =~ /SL/ or $msg =~ /sl/);
        $salida ="$nick: si vas hablar de windows te has equivocado de canal... Fuchi fuchi vete!!!" if ( $msg =~ /windows/ );
        $salida ="$nick: preguntale a $nick si puede comprate un reloj..." if ( $msg =~ /hora/ );
        $salida = extraer_frase($nick, $canal, $msg, "genericas", quien() ) if ( $msg =~ /bot/ or $msg =~ /troll/ );
        $salida = extraer_frase($nick, $canal, $msg, "groserias", quien() ) if ( $msg =~ /guevo.|mamaguevo.|maric.|paju.|pendej.|mariquit.|weon"/);
        $irc->yield( kick => $canal => $nick => 'porque le gustan asi' ) if ( $msg =~ /[8B]={2,}D/);
        $irc->yield( privmsg => $canal => $salida) if ($salida);
        }

sub dent
        {
        my $nick= $_[0];
        my $canal = $_[1];
        my $msg = $_[2];
        return "--$nick--";
        }

# bien pudiese ser utilizada una base de datos.
# en todo caso, como se lee cada vez que se invoca permite agregar frases al vuelo
sub extraer_frase
        {
        my $nick=@_[0];
        my $canal=@_[1];
        my $aux=@_[2];
        my $quien=@_[4];
        my $archivo="respuestas_".@_[3].".txt";
        my $salida="";
        open (FRASES, $archivo) || die "ERROR: no existe el archivo $archivo";
        my @frases = <FRASES>;
        close (FRASES);
        srand(time ^ $$);
        $salida = $frases[int(rand(@frases)-1)];
        $salida =~ s/____NICK____/$nick/g;
        $salida =~ s/____COIN____/$aux/g;
        $salida =~ s/____QUIEN____/$quien/g;
        return $salida;
        }

sub quien
        {
        my @everyone;
        @everyone = quienes();
        # escogemos un nick al azar dentro del numero de nicks en el canal
        srand(time ^ $$);
        my $q = int(rand(@everyone)-1);
        my $who = $everyone[$q];
        return $who;
        }

sub quienes
        {
        my @gente;
        $irc->yield(names => $channel);
        my @everyone = split(/\s+/, $todos);
        foreach (@everyone)
                {
                push(@gente,$_) if ($_ !~ /^$nickname$/);
                }
        return @gente;
        }

# evento que logra la salida de la funcion QUIENES
sub irc_353
{
        my ( $self, $kernel, $sender, $server, $who ) = @_[ OBJECT, KERNEL, SENDER, ARG0 .. ARG1 ];
        $who =~ /([^"]*)\s+:([^"]*)\s+/;
        my $chan  = $1;
        my $names = $2;
        $todos=$names;
        #my $nick = $$sender[0]{'nick'}; # vainas
        #$irc->yield( privmsg => $channel => $todos);
}

# esta subrutina extrae del archivo las frase al azar para responder
sub reconocimiento
        {
        my $nick=$_[0];
        my $msg=$_[1];
        my $canal = $_[2];
        my $respuesta;
        # se extrae una frase al azar, pero si se insulta al bot se responde al insulto
        $respuesta = extraer_frase($nick, $canal, $msg, "genericas", quien() ) unless ( $respuesta = groserias($nick, $canal, $msg) );
        $respuesta = "$nick: ignorante, yo no saludo, soy un robot, saluda a este 8===D" if ( $msg =~ / hola$/i or $msg =~ /^hola /i or $msg =~ /^ola /i or $msg =~ /^holis /i or $msg =~ /^epa /i);

        return $respuesta;
        }

sub groserias
        {
        my $nick=$_[0];
        my $canal = $_[1];
        my $msg=$_[2];
        my $salida;
        my %expresion = ( groserias => " put. | put.$|^put. |guevo| maric. |^maric. | maric.$|paju.|pendej.|mierda|");
        foreach my $llave (keys %expresion)
                {
                my $valor = $expresion{$llave};
                my $archivo = "respuestas.groserias.txt";
                $salida = extraer_frase ($nick, $canal, $msg, "groserias", quien()) if ( $msg =~ /($nickname)(.*)($valor)/) ;
                }
        return $salida;
        }

# conectar
sub _start
        {
        $irc->yield( register => 'all' );
        $irc->yield( connect => { } );
        undef;
        }

# entrar al canal
sub irc_001
        {
        $irc->yield( join => $channel );
        undef; # esto estaba en un código que copié. Es necesario?
        }

# cambios de nick
sub irc_nick
        {
        my $oldnick = (split /!/, $_[ARG0])[0];
        my $newnick = $_[ARG1];
        my $respuesta = "";
        &loguear("", "$oldnick cambio el nick a $newnick\n");
        $respuesta = extraer_frase ($newnick, $channel, 0, "cambio_de_nick");
        $irc->yield( privmsg => $channel => $respuesta);
        }

# alguien es pateado
sub irc_kick
        {
        my $nick = (split /!/, $_[ARG0])[0];
        my $canal = $_[ARG1];
        my $pateado = $_[ARG2];
        my $respuesta;
        # patean al bot?
        if ($nickname eq $pateado)
                {
                $respuesta="Y se puede saber por que $nick me patea?";
                $irc->yield( join => $canal);
                }
        else
                {
                $respuesta = extraer_frase ($nick, $canal, $pateado, "kick");
                &loguear("===", $respuesta);
                $irc->yield( privmsg => $canal => $respuesta);
                }
        }

sub irc_join
        {
        my $canal = $_[ARG1];
        my $nick = (split /!/, $_[ARG0])[0];
        my $respuesta;
        if ($nick =~ /^echevetroll/ || /^echevemaster/ || /^abr4xas/  )
                {
                $irc->yield( privmsg => $canal => "tu eres un cabeza de mojon con pelos");
                }
        }

sub irc_part
        {
        }

sub _default
        {
        }

sub loguear
        {
        # se loguea en formato mIRC por triste herencia
        # hace falta alguien que haga un script para convertir esto a xchat
        # el log se guarda para que lo analice el script PISG
        # ver http://radiognu.org/gnoll.html
        my $n  = localtime time;
        my @now = split(" ", $n);
        my $fecha = $now[1]." ".$now[2]." ".$now[3];
        my $quien;
        $quien = "<".$_[0].">" if ($_[0]);
        my $frase = $_[1];
        chomp ($frase);
        open (LOG,">> log.txt") || die ("No puedo escribir el LOG");
        print LOG "$fecha $quien $frase\n";
        close (LOG);
        }