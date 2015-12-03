<?php
$configPassword = "48shmuKAHT9BcAhZ";
include("config.ini.php");
if(isset($_POST['action'])){
  if($_POST['action'] == "update"){
    //Update the paragraphe
    if(notNull($_POST['id_text']) AND notNull($_POST['yAxis']) AND isset($_POST['text'])){
      //Update the texte of the paragraphe
      $time = time();
      $lang = "fr";
        if(startsWith($_POST['text'],"#h1#")){
            $type = "h1";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        elseif(startsWith($_POST['text'],"#h2#")){
            $type = "h2";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        elseif(startsWith($_POST['text'],"#h3#")){
            $type = "h3";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        elseif(startsWith($_POST['text'],"#nl#")){
            $type = "nl";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        elseif(startsWith($_POST['text'],"#l#")){
            $type = "l";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        elseif(startsWith($_POST['text'],"#p#")){
            $type = "p";
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text, type = :type; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, :type, :yAxis, :text, :lang)");
            $updateText->bindParam(":type",$type);
            $_POST['text'] = ltrim($_POST['text'],"#".$type."#");
        }
        else{
            $updateText = $bdd->prepare("INSERT IGNORE INTO `stylo`.`paragraphe` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, 'p', :yAxis, :text, :lang) ON DUPLICATE KEY UPDATE text = :text; INSERT IGNORE INTO `stylo`.`paragraphe_history` (`id_text`, `maj`, `type`, `yAxis`, `text`, `lang`) VALUES (:id_text, :time, 'p', :yAxis, :text, :lang)");
        }
      $updateText->bindParam(":id_text",$_POST['id_text']);
      $updateText->bindParam(":text",$_POST['text']);
      $updateText->bindParam(":yAxis",$_POST['yAxis']);
      $updateText->bindParam(":time",$time);
      $updateText->bindParam(":lang",$lang);
      $updateText->execute() or die('Impossible d\'update le paragraphe');
      $json['error'] = 0;
      header('Content-Type: application/json');
      echo json_encode($json);
    }
    else{
      $json['error'] = 1;
      $json['cause'] = "var not set";
      header('Content-Type: application/json');
      echo json_encode($json);
    }
  }
  elseif($_POST['action'] == "add"){
      if(notNull($_POST[id_text]) AND notNull($_POST['start']) AND notNull($_POST['offset'])){
        //decale les paragraphes suivant l'insert
          $addParagraphe = $bdd->prepare("update paragraphe SET yAxis = yAxis + :offset where yAxis > :start  AND id_text = :id_text ORDER BY yAxis DESC;update paragraphe_history SET yAxis = yAxis + :offset where yAxis > :start  AND id_text = :id_text ORDER BY yAxis DESC");
          $id_text = 1;
          $addParagraphe->bindParam(":offset",$_POST['offset']);
          $addParagraphe->bindParam(":start",$_POST['start']);
          $addParagraphe->bindParam(":id_text",$_POST['id_text']);
          $addParagraphe->execute() or die('Impossible d\'ajouter de paragraphe');
          $json['error'] = 0;
          header('Content-Type: application/json');
          echo json_encode($json);
    }
    else{
      $json['error'] = 1;
      $json['cause'] = "var not set";
      header('Content-Type: application/json');
      echo json_encode($json);
    }
  }
  elseif($_POST['action'] == "remove"){
      if(notNull($_POST[id_text]) AND notNull($_POST['start']) AND notNull($_POST['offset'])){
        //supprime les paragraphes
         $supprParagraphe = $bdd->prepare("DELETE FROM paragraphe WHERE yAxis >= :start AND yAxis < :end AND id_text = :id_text");
         $supprParagraphe->bindParam(":start", $_POST['start']);
         $end = $_POST['start'] + $_POST['offset'];
         $supprParagraphe->bindParam(":end", $end);
         $supprParagraphe->bindParam(":id_text", $_POST['id_text']);
         $supprParagraphe->execute() or die('Impossible de supprimer les lignes');

        //decale les paragraphes apres la supression
          $addParagraphe = $bdd->prepare("update paragraphe SET yAxis = yAxis - :offset where yAxis > :start AND id_text = :id_text ORDER BY yAxis ASC");
          $addParagraphe->bindParam(":offset",$_POST['offset']);
          $addParagraphe->bindParam(":start",$_POST['start']);
          $addParagraphe->bindParam(":id_text",$_POST['id_text']);
          $addParagraphe->execute() or die('Impossible de deplacer les lignes après la suppression');

        //Update paragraphe_history SET del = 1, yAxis = 0 WHERE yAxis >= :start AND yAxis < :end AND id_text = :id_text
        $updParagraphe = $bdd->prepare("Update paragraphe_history SET del = 1, yAxis = 0 WHERE yAxis >= :start AND yAxis < :end AND id_text = :id_text");
        $updParagraphe->bindParam(":start", $_POST['start']);
        $end = $_POST['start'] + $_POST['offset'];
        $updParagraphe->bindParam(":end", $end);
        $updParagraphe->bindParam(":id_text", $_POST['id_text']);
        $updParagraphe->execute() or die('Impossible de backups les lignes');

        $addParagraphe = $bdd->prepare("update paragraphe_history SET yAxis = yAxis - :offset where yAxis > :start AND id_text = :id_text ORDER BY yAxis ASC");
        $addParagraphe->bindParam(":offset",$_POST['offset']);
        $addParagraphe->bindParam(":start",$_POST['start']);
        $addParagraphe->bindParam(":id_text",$_POST['id_text']);
        $addParagraphe->execute() or die('Impossible de deplacer les lignes en backup après la suppression');


          $json['error'] = 0;
          header('Content-Type: application/json');
          echo json_encode($json);
    }
    else{
      $json['error'] = 1;
      $json['cause'] = "var not set";
      header('Content-Type: application/json');
      echo json_encode($json);
    }
  }
  elseif($_POST['action'] == "meta"){
    if(notNull($_POST['id_text']) AND notNull($_POST['field']) AND isset($_POST['text'])){
      if($_POST['field'] == "titre"){
        $update = true;
        $updateMeta = $bdd->prepare("INSERT INTO `stylo`.`description` (`id_text`, `lang`, `title`, `subtitle`, `descript`) VALUES (:id_text, :lang, :text, '', '') ON DUPLICATE KEY UPDATE title = :text");
      }
      elseif($_POST['field'] == "soustitre"){
        $update = true;
        $updateMeta = $bdd->prepare("INSERT INTO `stylo`.`description` (`id_text`, `lang`, `title`, `subtitle`, `descript`) VALUES (:id_text, :lang, '', :text, '') ON DUPLICATE KEY UPDATE subtitle = :text");
      }
      elseif($_POST['field'] == "description"){
        $update = true;
        $updateMeta = $bdd->prepare("INSERT INTO `stylo`.`description` (`id_text`, `lang`, `title`, `subtitle`, `descript`) VALUES (:id_text, :lang, '', '', :text) ON DUPLICATE KEY UPDATE descript = :text");
      }
      else{
        $json['error'] = 1;
        $json['cause'] = "No meta understood";
        header('Content-Type: application/json');
        echo json_encode($json);
      }
      if($update){
        $lang = "fr";
        $updateMeta->bindParam(":id_text",$_POST['id_text']);
        $updateMeta->bindParam(":text",$_POST['text']);
        $updateMeta->bindParam(":lang",$lang);
        $updateMeta->execute() or die("Impossible de mettre a jour les metas.");
        $json['error'] = 0;
          header('Content-Type: application/json');
          echo json_encode($json);
      }
    }
  }
  else{
    $json['error'] = 1;
    $json['cause'] = "No action understood";
    header('Content-Type: application/json');
    echo json_encode($json);
  }

}
else{
  $json['error'] = 1;
  $json['cause'] = "No action set";
  header('Content-Type: application/json');
  echo json_encode($json);
}

 ?>
