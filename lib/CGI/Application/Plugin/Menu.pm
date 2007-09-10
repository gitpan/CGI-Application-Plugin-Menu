package CGI::Application::Plugin::Menu;
use strict;
use LEOCHARRE::DEBUG;
use warnings;
use Carp;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw/ Exporter /;
@EXPORT = qw(menu ___menus_ ___menus_order menus menus_count);
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub menu {
   my ($self,$label) = @_;
   $label ||= 'main';
   
   unless ( exists $self->___menus_->{$label} ) {
      $self->___menus_->{$label} = new CGI::Application::Plugin::MenuObject;
      $self->___menus_->{$label}->_name_set($label);
      push @{$self->___menus_order},$label;
   }
   return $self->___menus_->{$label};
}

sub menus {
   my $self = shift;
   return $self->___menus_order;
}

sub ___menus_ {
   my $self = shift;
   $self->{'__CGI::Application::Plugin::Menu::Objects'} ||={};
   return $self->{'__CGI::Application::Plugin::Menu::Objects'};
}

sub ___menus_order {
   my $self = shift;
   $self->{'__CGI::Application::Plugin::Menu::ObjectsOrder'} ||=[];
   return $self->{'__CGI::Application::Plugin::Menu::ObjectsOrder'};  
}

sub menus_count {
   my $self = shift;
   my $count = scalar @{$self->menus};
   return $count;
}

1;




package CGI::Application::Plugin::MenuObject;
use strict;
use LEOCHARRE::DEBUG;
use warnings;
use Carp;

sub new {
   my $class = shift;
   my $self = {};
   bless $self,$class;
   return $self;
}

sub name {
   my $self = shift;
   $self->{_name_} ||= 'main'; # redundant (?)
   return $self->{_name_};
}

sub _name_set {
   my($self,$val) = @_;
   defined $val or confess;   
   return $self->{_name_} = $val;
   return 1;
}


sub count {
   my $self = shift;
   my $a = $self->_get_menuitems_order;
   return scalar @$a;
}

sub loop {
   my $self = shift;
   my $loop = $self->_get_main_menu_loop;
   return $loop;
}

sub add {
   my($self,$arg1,$label) = @_;
   defined $arg1 or confess('missing argument');

   my $url;

   if (__is_runmode_name($arg1) ){
      $url = "?rm=$arg1"; # TODO, what is the runmode param string method in CGI::Application ?
      $label = __runmode_name_prettyfy($arg1) unless defined $label;
   }
   else {
      $url = $arg1;
   }
   $label = $url unless defined $label;

   debug(" arg1 $arg1, url $url, label $label\n");

   $self->_add_menu_item($arg1,$url,$label) or return 0;
   return 1;
}

sub _add_menu_item {
   my ($self,$arg1,$url,$label) = @_; 
   
   my $hash = $self->_get_menuitems;
   my $array = $self->_get_menuitems_order;

   if (exists $hash->{$arg1}){
      debug("Menu item [$arg1] was already entered. Skipped.\n");
      return 0;
   }

   push @$array, $arg1;
      

   $hash->{$arg1} = {
      arg1 => $arg1,
      url => $url,
      label => $label,
   };

   return 1;   
}

sub _get_main_menu_loop {
   my $self = shift;
   
   my $hash = $self->_get_menuitems;
   my $array = $self->_get_menuitems_order;

   my $loop=[];
   for (@$array){
      my  $arg1 = $_;
      push @$loop, { url => $hash->{$arg1}->{url}, label => $hash->{$arg1}->{label} };
   }
   return $loop;   
}

sub _get_menuitems {
   my $self = shift;
   $self->{__menuitems__} ||={};
   return $self->{__menuitems__};
}

sub _get_menuitems_order {
   my $self = shift;
   $self->{__menuitems__order__} ||=[];
   return $self->{__menuitems__order__};
}

sub __runmode_name_prettyfy {
   my $val = shift;
   
   my $label = lc $val;
   $label=~s/\_/ /g;
   $label=~s/\b([a-z])/uc $1/eg;
   return $label;   
}

sub __is_runmode_name {
   my $val = shift;
   $val =~/^[a-z0-9_]+$/i or return 0;
   return 1;
}





1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::Menu - manage navigation menus for cgi apps

=head1 SYNOPSIS
  
   use base 'CGI::Application';   
   use CGI::Application::Plugin::Menu;

   sub _set_menus_in_template {
      my $self = shift;


      my $m = $self->menu('main');
   
      $m->add('home','home page');
      $m->add('view_stats');
      $m->add('http://cpan.org','visit cpan');

      $m->name; # returns 'main', for this example

      # GETTING THE HTML TEMPLATE LOOP
   
      my $main_menu_loop = $m->loop; 
   
      my $tmpl = $self->this_method_returns_HTML_Template_object;
      
      $tmpl->param( 'MAIN_MENU' => $main_menu_loop );
   
      #or
      $tmpl->param( 'MAIN_MENU' => $self->menu_get('main_menu')->loop );   

      # IN YOUR HTML TEMPLATE:
      # 
      # <ul>
      #  <TMPL_LOOP MAIN_MENU>  
      #  <li><a href="<TMPL_VAR URL>"><TMPL_VAR LABEL></a></li>
      #  </TMPL_LOOP>
      # </ul>

      return 1;
   }

=head1 DESCRIPTION

This is a simple way ot having menus in your cgi apps.

=head1 METHODS

=head2 menu()

if you don't provide an argument, the default is used, which is 'main'.
returns L<A MENU OBJECT>

=head2 menus()

returns array ref of names of menus that exist now.
They are in the order that they were instanced

   my $m0 = $self->menu('main');
   $m0->add('home');
   $m0->add('news');
   
   my $m1 = $self->menu('session');
   $m1->add('logout');
   $m1->add('login_history');
   
   for ( @{$self->menus} ){
      my $m = $_;
      my $menu_name = $m->name;
      my $loop_for_html_template = $m->loop;
   }


=head1 A MENU OBJECT

Are instances of CGI::Application::Plugin::MenuObject.

=head2 METHODS

=head3 name()

returns name of the menu.

=head3 add()

argument is url or runmode
optional argument is label 

If the first argument has no funny chars, it is treated as a runmode.

The label is what will appear in the link text
If not provided, one will be made. 
If you have a runmode called see_more, the link text is "See More".

The link will be 

   <a href="?=$YOURRUNMODEPARAMNAME=$ARG1">$ARG2</a>

So in this example:

   $m->add('view_tasks');

The result is:

   <a href="?rm=view_tasks">View Tasks</a>

=head3 loop()

get loop suitable for HTML::Template object
See SYNOPSIS.

=head2 ADDING MENU ITEMS

   my $m = $self->menu_get('main menu');

   $m->add('home');   
   $m->add('http://helpme.com','Need help?');
   $m->add('logout');
   
Elements for the menu are shown in the order they are inserted.




=head1 AUTOMATICALLY GENERATING A MENU

See CGI::Application::Plugin::AutoMenuitem

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

CGI::Application
HTML::Template
LEOCHARRE::DEBUG

=cut





