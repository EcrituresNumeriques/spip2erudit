<?php
$configPassword = "48shmuKAHT9BcAhZ";
include("config.ini.php");
   header('Content-Type: application/xml');
   $xml = new DOMDocument('1.0', 'utf-8');
   $xml->formatOutput = true;
//Main article
   $article = $xml->createElement( "Article" );

   $xmlns = $xml->createAttribute('xmlns');
   $xmlns->value = "http://www.erudit.org/xsd/article";
   $xmlnsxsi = $xml->createAttribute('xmlns:xsi');
   $xmlnsxsi->value = "http://www.w3.org/2001/XMLSchema-instance";
   $xsischemaLocation = $xml->createAttribute('xsi:schemaLocation');
   $xsischemaLocation->value = "http://www.erudit.org/xsd/article http://www.erudit.org/xsd/article/3.0.0/eruditarticle.xsd";
   $qualtraitement = $xml->createAttribute('qualtraitement');
   $qualtraitement->value = "complet";
   $idproprio = $xml->createAttribute('idproprio');
   $idproprio->value = "???";
   $typeart = $xml->createAttribute('typeart');
   $typeart->value = "autre";
   $lang = $xml->createAttribute('lang');
   $lang->value = "fr";
   $ordseq = $xml->createAttribute('ordseq');
   $ordseq->value = "3";

   $xml->appendChild( $article );
   $article->appendChild( $xmlns );
   $article->appendChild( $xmlnsxsi );
   $article->appendChild( $xsischemaLocation );
   $article->appendChild( $qualtraitement );
   $article->appendChild( $idproprio );
   $article->appendChild( $typeart );
   $article->appendChild( $lang );
   $article->appendChild( $ordseq );


//Admin
   $admin = $xml->createElement( "admin" );
   $article->appendChild( $admin );
   
//info Article
   $infoarticle = $xml->createElement("infoarticle");
   $admin->appendChild( $infoarticle );
   
   $idpublic  = $xml->createElement("idpublic","article1");
   $infoarticle->appendChild( $idpublic );
   $scheme = $xml->createAttribute("scheme");
   $scheme->value = "doi";
   $idpublic->appendChild($scheme);

//Revue
   $revue = $xml->createElement( "revue" );
   $admin->appendChild($revue);
   
   $titrerev = $xml->createElement("titrerev","Sens Public");
   $titrerevabr = $xml->createElement("titrerevabr","sp");
   $idissnnum = $xml->createElement("idissnnum","2104-3272");
   $revue->appendChild($titrerev);
   $revue->appendChild($titrerevabr);
   $revue->appendChild($idissnnum);

//print
   echo $xml->saveXML();
?>