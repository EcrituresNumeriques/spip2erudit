<?php
if($configPassword != "48shmuKAHT9BcAhZ")
{
    die('Error 0x00000001');
}
else{
    $db_user = "stylo";
    $db_base = "stylo";
    $db_pass = "sL8JfhBGzjCD7xGL";
    $db_log = "mysql:host=localhost;dbname=$db_base";
    try
    {
        $bdd = new PDO($db_log, $db_user, $db_pass);
    }
    catch (Exception $e)
    {
        die('Erreur : ' . $e->getMessage());
    }
    $bdd->query("SET NAMES UTF8");
    session_start();
    //include functions
    include('function.php');
    inputSecurity();


}
