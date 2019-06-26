<?php
function openConn(){
    return  pg_connect("host=54.153.58.125 dbname=app user=app password=toor");
}

function closeConn($conn){
   pg_close($conn);
}

?>

