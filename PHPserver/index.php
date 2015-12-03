<?php
$configPassword = "48shmuKAHT9BcAhZ";
include("config.ini.php");
?>
<!DOCTYPE html>
<meta name="robots" content="noindex">
<html>
<head>
<link href="side/reset.css" rel="stylesheet" type="text/css">
<link href="side/style.css" rel="stylesheet" type="text/css">
<script src="https://code.jquery.com/jquery-3.0.0-alpha1.js"></script>
<script src="side/editor.js"></script>
  <meta charset="utf-8">
  <title>Stylo</title>
<style></style>
</head>
<body>
  <article>
    <nav id="topColumn">
      <ul type="onglets">
        <li>Fichier</li>
        <li>Editer</li>
        <li>Partager</li>
        <li id="downloadXML">XML</li>
      </ul>
      <ul>
        <li>Aide</li>
        <li>Compte</li>
      </ul>
    </nav>
    <section id="meta">
     <h1>Metadonnées</h1>
     <?php
        $fetchMeta = $bdd->prepare("SELECT * FROM description WHERE id_text = :id_text AND lang = :lang");
        $id_text = 1;
        $lang = "fr";
        $fetchMeta->bindParam(":id_text", $id_text);
        $fetchMeta->bindParam(":lang", $lang);
        $fetchMeta->execute() or die("Impossible de récupérer les métas");
        $fetch = $fetchMeta->fetch();
        (notNull($fetch['title']) ? $title = $fetch['title'] : $title = "");
        (notNull($fetch['subtitle']) ? $subtitle = $fetch['subtitle'] : $subtitle = "");
        (notNull($fetch['descript']) ? $description = $fetch['descript'] : $description = "");
?>
      <input type="text" id="inputtitre" placeholder="Titre" value="<?=$title?>">
      <input type="text" id="inputsoustitre" placeholder="Sous-titre" value="<?=$subtitle?>">
      <textarea id="inputdescription" placeholder="description"><?=$description?></textarea>
      <p id="inputauteur">
        <span class="title">Auteurs : </span><span class="add">Ajouter un auteur</span>
      </p>
      <p id="inputtags">
        <span class="title">Tags : </span><span class="add">Ajouter un tag</span>
      </p>
    </section>
    <section id="text" contenteditable="true" onpaste="OnPaste_StripFormatting(this, event);">
      <?php
        $fetchText = $bdd->prepare("SELECT * FROM paragraphe WHERE id_text = :id_text ORDER BY yAxis ASC");
        $id_text = 1;
        $fetchText->bindParam(":id_text",$id_text);
        $fetchText->execute() or die("Unable to fetch text");
        if($fetchText->rowCount() > 0){
        while($row = $fetchText->fetch()){
          echo('      <p class="typeIn '.$row['type'].'" data-yAxis="'.$row['yAxis'].'">'.$row['text'].'</p>');
        }
        }
        else{
          echo('      <p class="typeIn" data-yAxis="1">test</p>');
        }
      ?>

    </section>
    <section id="bib"></section>

  </article>
<script>
</script>
</body>
</html>
