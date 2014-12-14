  use Mail::SendEasy ;
  my $mail = new Mail::SendEasy(
  smtp => 'smtp.gmail.com' ,
  user => 'emmett.traynor@gmail.com' ,
  pass => neowelt2007 ,
  port => 2525 ,
  ) ;
  
  my $status = $mail->send(
  from => 'emmett.traynor@gmail.com' ,
  from_title => 'AWS Production Server' ,
  reply => 'emmett.traynor@gmail.com' ,
  error => 'emmett.traynor@gmail.com' ,
  to => 'emmett.traynor@gmail.com' ,
  cc => '' ,
  subject => "Web Application Deploy" ,
  msg => "Congratulations \n Your Web Application deploy to Amazon WebServices Production Server was successful." ,
  html => "Congratulations \n Your Web Application deploy to Amazon WebServices Production Server was successful." ,
  msgid => "0101" ,
  ) ;
  
  if (!$status) { print $mail->error ;}
