<?php
 try {
        $dbexer_dbname 		= "exer_db";
        $dbexer_host 		= "127.0.0.1";
        $dbexer_username 	= "admin_exer";
        $dbexer_password 	= trim(shell_exec('cat /etc/mysql/otp.conf'));
        
        $db = new PDO("mysql:host=$dbexer_host;dbname=$dbexer_dbname;charset=utf8", $dbexer_username, $dbexer_password);
    } catch (Exception $exception) {
        die('An error occurred : ' . $exception ->getCode() . ' ' . $exception->getMessage() . ').');
    }

	$FIELD_INSERT_TEMPLATES= "UPDATE  `otp_mailing`  SET content= ' Hello {{username}} ! <br> <p>Your administrator, responsible for this company <b>{{company}}</b>, shared with you a unique link to easily retrieve your OTP information online.</p> <br> <div style=\"text-align: left; cursor: auto; color: rgb(51, 51, 51); font-family: Corbel; font-size: 14px; line-height: 1.44;\"> <b>Please access the link directly by clicking the \"Go to Link\" button below to get the related OTP information, or copy the following link: <a title=\"Your OTP EXER link\" target=\"_blank\" href=\"{{link}}\">{{link}}</a> </b> </div> ';";
	$req1 = $db->prepare($FIELD_INSERT_TEMPLATES);
    $req1->execute(array($FIELD_INSERT_TEMPLATES));
	
	$FIELD_INSERT_TEMPLATES_link= "UPDATE  `otp_mailing`  SET content_link= '
<div class=\"box text-center\">
	{{{logo}}}
	<h2>{{company}}</h2>
	<div>
		<p>
			<b>Username :</b> {{username}}<br>
			<b>key name :</b> {{keyname}}<br>
			<b>Issuer :</b> {{issuer}}
		</p>
	</div>
</div><br>

<p>Your single-use QRCode is available on this page. These data are strictly personal and are the responsibility of the holder or user.
You can, if necessary, click on the QR Code displayed on your screen to enlarge it.</p>

<div class=\"text-center\">
	{{{qrcode}}}
</div>
<hr>
<fieldset>
	<legend>How do I retrieve my OTP codes?</legend>
	<exer class=\"font-weight-light\">To manage the codes generated by the EXER OTP server, we recommend the following applications:</exer>
	<br><br>
	<div class=\"row text-center\">
		<div class=\"col-lg-6\">
			<a href=\"{{CustomBtn1}}\" target=\"_blank\">
				<img style=\"height: 4rem;\" src=\"/assets/images/appstore.png\">
			</a>
		</div>
		
		<div class=\"col-lg-6\">
			<a href=\"{{CustomBtn2}}\" target=\"_blank\">
				<img style=\"height: 4rem;\" src=\"/assets/images/playstore.png\">
			</a>
		</div>
	</div>
</fieldset>
';
	

 ';";
 $req2 = $db->prepare($FIELD_INSERT_TEMPLATES_link);
 $req2->execute(array($FIELD_INSERT_TEMPLATES_link));
?>
