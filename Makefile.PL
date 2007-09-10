use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'CGI::Application::Plugin::Menu',
   VERSION_FROM => 'lib/CGI/Application/Plugin/Menu.pm',
   PREREQ_PM => {
     'LEOCHARRE::DEBUG' => '1.02',
     'CGI::Application' => 0,
     'Smart::Comments' => 0,
   }, 
);
