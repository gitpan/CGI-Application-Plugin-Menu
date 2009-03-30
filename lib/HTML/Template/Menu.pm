package HTML::Template::Menu;
use strict;
use LEOCHARRE::DEBUG;
use warnings;
use Carp;

$HTML::Template::Menu::DEFAULT_TMPL = q{
<div class="<TMPL_VAR MAIN_MENU_CLASS>"><p>
<TMPL_LOOP MAIN_MENU_LOOP><nobr><b><a href="<TMPL_VAR URL>">[<TMPL_VAR LABEL>]</a></b></nobr>
</TMPL_LOOP></p></div>};


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

sub name_set {
   my($self,$val) = @_;
   defined $val or confess;
   $self->_name_set($val);
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
   elsif (__is_url($arg1) ){
      $label = __url_prettyfy($arg1) unless defined $label;
      $url = $arg1;
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

sub __prettify_string {
   my $val = shift;
   my $label = lc $val;
   $label=~s/\W/ /g;
   $label=~s/^\s+|\s+$//g;
   
   $label=~s/\_+|\s{2,}/ /g;
   $label=~s/\b([a-z])/uc $1/eg;
   return $label;   
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

sub __is_url {
   my $val = shift;
   return 0 if __is_runmode_name($val);
   return 1;
   
}

sub __url_prettyfy {
   my $val = shift;
   if ($val eq '/'){ return 'Home'; }
   $val=~s/\/+$//;
   $val=~s/^.+\/+//;
   $val=~s/\.\w{1,5}$//;
   $val=~s/\.s*html*\?.+//i;
   $val=~s/\.\w{3}\?.+//i;

   my $label = __prettify_string($val);
   return $label;
}

sub output {
   my $self = shift;
   require HTML::Template;
   my $tmpl = new HTML::Template( 
      die_on_bad_params => 0, 
      scalarref => \$HTML::Template::Menu::DEFAULT_TMPL,
   ) 
      or die('cant instance HTML::Template object');
   
   $tmpl->param( 
      MAIN_MENU_LOOP => $self->loop, 
      MAIN_MENU_CLASS => $self->menu_class );
   return $tmpl->output;
}

sub menu_class {
   my $self = shift;
   $self->{_menu_class_} ||= 'menu_class_'.$self->name;
   return $self->{_menu_class_};
}

sub menu_class_set {
   my($self,$val) =@_;
   defined $val or confess('missing arg');
   $val=~s/\W//g;
   $self->{_menu_class_} = $val;
   return 1;
}



1;

=pod

=head1 NAME

HTML::Template::Menu

=head1 SYNOPSIS

   use HTML::Template::Menu;

   my $m = new HTML::Template::Menu;

   $m->add('/','home');
   $m->add('/contact.html');



=head1 METHODS

=head3 new()

new menu



=head3 name()

returns name of the menu.

=head3 name_set()

sets name of menu, argument is string

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

=head2 count()

returns count of items in this menu

=head2 menu_class()

what the TMPL_VAR MAIN_MENU_CLASS will hold

=head2 menu_class_set()

arg is string
sets the TMPL_VAR MAIN_MENU_CLASS

=head2 output()

If you just want the output with the default hard coded template.
The default template code is stored in:

   $CGI::Application::Plugin::MenuObject::DEFAULT_TMPL


=head2 ADDING MENU ITEMS

   my $m = $self->menu_get('main menu');

   $m->add('home');   
   $m->add('http://helpme.com','Need help?');
   $m->add('logout');
   
Elements for the menu are shown in the order they are inserted.

=head1 DEFAULT TEMPLATE

You may want to change this.

   <div class="<TMPL_VAR MAIN_MENU_CLASS>"><p>
   <TMPL_LOOP MAIN_MENU_LOOP><nobr><b><a href="<TMPL_VAR URL>">[<TMPL_VAR LABEL>]</a></b></nobr>
   </TMPL_LOOP></p></div>

One way to change it:

   $HTML::Template::Menu::DEFAULT_TMPL = q{
   <div class="<TMPL_VAR MAIN_MENU_CLASS>"><p>
   <TMPL_LOOP MAIN_MENU_LOOP><nobr><b><img src="/gfx/bullet.png"> <a href="<TMPL_VAR URL>">[<TMPL_VAR LABEL>]</a></b></nobr>
   </TMPL_LOOP></p></div>
   };   

Or you can just get the menu loop and inject into your template

   my $menu_loop = $m->_get_main_menu_loop;


=head1 AUTHOR

Leo CHarre leocharre at cpan dot org

=head1 SEE ALSO

CGI::Application::Plugin::Menu

=cut



