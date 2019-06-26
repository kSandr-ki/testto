<?php
require 'flight/Flight.php';
include './db.php' ;
include './notify.php' ;

function check(){ 
    $conn = openConn();
    $uri=$_SERVER['REQUEST_URI'];
    $user_ip=$_SERVER['REMOTE_ADDR'];
    $query="select * from blacklisted where path='".$uri."'and ip='".$user_ip."';";
    //echo $query."<br>" ;
    $res=pg_query($conn, $query);
    if ( pg_fetch_all($res) ) {
      Flight::redirect('/blacklisted', 301);
    }
    closeConn($conn);
}

function Fibonacci($number){ 
    if ($number == 0) 
        return 0;     
    else if ($number == 1) 
        return 1;     
      
    // Recursive Call to get the upcoming numbers 
    else
        return (Fibonacci($number-1) +  
                Fibonacci($number-2)); 
} 
check();
Flight::route('GET|POST /test', function(){
   echo 'test' ;
   //Flight::response()->status(444);
   //Flight::redirect('/blacklisted', 301);

});
Flight::route('GET|POST /info', function(){
   echo "<html><head></head><body><h2>This is information page</h2> <br></body></html>" ;
   //Flight::response()->status(444);
   //Flight::redirect('/blacklisted', 301);

});


Flight::route('GET|POST /', function(){
    $number = Flight::request()->query['n'];
    if (isset($number)) {
     if ( (int)$number > 30 ) { 
       $response = array('status:'=>'error', 'text'=>'too big number pelase use number less 30');
       Flight::json($response,400);
       return;
     }
      //$number=$_GET['n'];
        for ($counter = 0; $counter < $number; $counter++){   
            echo Fibonacci($counter),' '; 
        } 
     } 
    else {
       echo "You can use \"n\" param for getting fibonacci series, like http://".$_SERVER['HTTP_HOST']."?n=10";
    }

});
Flight::route('GET|POST /blacked', function(){
     $conn = openConn();
     $secret_token = 'bigsecret' ;
     $ip    = Flight::request()->query['ip'];
     $path  = Flight::request()->query['path'];
     $token = Flight::request()->query['token'];
     $action = Flight::request()->query['action'];
     if ( $token != $secret_token ) {
         $response = array('status:'=>'error', 'text'=>'bad token ');
         Flight::json($response,400);
         return;
     }  
     if ( $action == 'list' ) {
        $query="select * from  blacklisted ;";
        $response=pg_query($conn, $query);
        closeConn($conn);
        Flight::json(pg_fetch_all($response),200);
        return;
      }
     if (empty($ip)) { 
       $response = array('status:'=>'error', 'text'=>'bad params '.$ip);
       Flight::json($response,400);
       return;
     }
     if (empty($path)) { 
       $response = array('status:'=>'error', 'text'=>'bad params '.$path);
       Flight::json($response,400);
       return;
     }
     if (empty($action)) { 
       $response = array('status:'=>'error', 'text'=>'bad params '.$action);
       Flight::json($response,400);
       return;
     }
     if ( $action == 'add' ) {
        $query="insert into blacklisted (ip, path, blacklisted_on) values ('".$ip."','".$path."',current_timestamp);";
        $res=pg_query($conn, $query);

      closeConn($conn);

      $email_message="ip is blacklisted ".$_SERVER['REMOTE_ADDR'];
      notify($email_message);

      $response = array('status:'=>'ok', 'text'=>$ip.':'.$path.' - is added to a blacklist');
      Flight::json($response,200);
        return;
     }

});

Flight::route('GET|POST /blacklisted', function(){

      $response = array('status:'=>'blacked', 'text'=>'you in blacklist');
      Flight::json($response,444);
      return;
});

Flight::start();
