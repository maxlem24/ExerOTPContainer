<?php
    try {
        $dbexer_dbname 		= "exer_db";
        $dbexer_host 		= "127.0.0.1";
        $dbexer_username 	= "admin_exer";
        $dbexer_password 	= trim(shell_exec('cat /etc/mysql/otp.conf'));
        
        $db = new PDO("mysql:host=$dbexer_host;dbname=$dbexer_dbname;charset=utf8", $dbexer_username, $dbexer_password);
    } catch (Exception $exception) {
        die('Erreur(s) rencontrée(s) : ' . $exception ->getCode() . ' ' . $exception->getMessage() . ').');
    }

	// Change app_exerotp user password
	$sqlReq = "SET PASSWORD FOR 'app_exerotp'@'localhost' = PASSWORD('".$dbexer_password."');";
    $req = $db->prepare($sqlReq);
    $req->execute(array($sqlReq));
?>