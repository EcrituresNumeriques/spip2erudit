xquery version "3.0" ;

(:~
 : This module transforms SPIP XML export to erudit XML
 :
 : @version 0.5
 : @since 2015-11-04
 : @date 2017-04-18
 : @author emchateau + lakonis
 :
 : traité 2017-04-13:
 :   - suppr balise <histpapier>
 :   - gestion attribut @lang pour balise <partiesann>
 :   - gestion attribut @lang pour balise racine
 :   - gestion attribut @idref/@horstheme pour balise racine et supprime l'un ou l'autre
 :   - gestion <droitauteur> = creativecommons
 :   - gestion <grtheme> Varia si n'appartient pas à un dossier
 :   - dans <grmotcles> suppression mots-clé titre de dossier, mot-clé admin
 :   - gestion attribut @typeart dans balise racine
 : traité le 2017-04-18:
 :   - cas particulier Sommaire de dossier : gestion attribut @idref, <surtitre>
 :   - gestion balise <surtitre> pour article Varia (hors-dossier)
 :
 : traité le 2017-07-05 (traitement correctifs Erudit):
 :   - ajout attribut image xlink:type (https://gitlab.erudit.org/EcrituresNumeriques/senspublic/commit/fabe452402ca8de73b9e6f153549fb78898357ea)
 : traité le 2017-09-11/12 (traitements correctifs Erudit):
     - traitement des balises vides (voir sur Notes Suivi correctif) :
        - para/alinea vide
        - liensimple pour des ancres vides (contrairement à Spip, on considèrera que les ancres de retour sont placées au niveau de la note et non du paragraphe qui contient la note)
 :       
 : traité le 2017-09-18 (intégration de map keywords pour accélérer le script : les joins des "tables" sont fait en amont et les tables sont passés en arguments) 
 :       
 : traité le 2018-01-05 (traitement correctifs Erudit):
 :   - maj id revue voir commit https://gitlab.erudit.org/EcrituresNumeriques/senspublic/commit/11e86d9d7187c795c87955a1388ad1a2e8f35ab6
 :   - correction pour les figcaption de figure et pour les title de img (mais traitement manuel pour les autres pb, notamment les images codées en dur dans la base)
 : traité le 2018-01-06 (traitement correctifs Erudit):
 :   - id numero et id article = ""
 :   - supp balise DOI (voir commit https://gitlab.erudit.org/EcrituresNumeriques/senspublic/commit/d580b7071d2f722e44c628ed7993ee265534f59b)
 : traité le 2018-01-07 (traitement correctifs Erudit):
 :   - prise en compte des balises <cite>
 :   - suppression balise <exposant> contenant un espace insécable
 : traité le 2018-01-08 (traitement correctifs Erudit):
 :   - traitement balise marquage vide i, em, strong
 :   - élargissement de l'échantillon et réorganisation des dossiers de sortie
 :   - affinage du test sur spip:a qui évacue tous les potentiels liens externes contenant "anc" ou "sym" -> fn:ends-with
 :
 :
 : OLD TODO
 : @todo br, num structure, titres h2 etc.
 : @todo object (vidéos)
 : @todo multiple p notes
 : @issue 1152 didn't get biblio
 :)

declare default element namespace 'http://www.erudit.org/xsd/article' ;

declare namespace spip = "http://spip.net/tagset/" ;
declare namespace sp = "http://sens-public.org/sp/" ;
declare namespace functx = "http://www.functx.com" ;
declare namespace xlink = "http://www.w3.org/1999/xlink" ;

declare default function namespace 'local' ;

declare variable $local:base := file:base-dir() ;
declare variable $local:groupes := fn:doc($local:base || 'groupes.xml') ;




(:~
 : This function writes the articles files
 : @return for each article write an XML file named with its id prefixed by "sens-public-" in the $path directory
 :)
declare function writeArticles($refs as map(*)*) as document-node()* {
  let $path := $local:base || '/xml/'
  let $pathtest := $local:base || '/xmltest/'
  let $pathgitlab := '/home/nicolas/gitlab/senspublic/data/phase1/articleEN/'
  let $rubriques := map {
  '55' : 'Revue en ligne',
  '58' : 'Essai',
  '60' : 'Création',
  '65' : 'L édition papier de Sens Public',
  '68' : 'Archive',
  '71' : 'info revue',
  '76' : 'Lecture',
  '107': 'Actes de colloque',
  '109': 'Sommaire dossier', (:109 = Dossiers sur Spip :)
  '113': 'Entretien',
  '114': 'Chronique',
  '115': 'Qui sommes-nous ?',
  '116': '2. Infos générales',
  '118': 'Lu sur le web',
  '119': '3. Autres informations'
  }
  
  (: construit une map clé-valeur avec id-article id.s-keyword.s :)
  let $keywords_articles := db:open('sens-public')//spip:spip_mots_articles
  let $mapArticleKeyword := map:merge(
    for $keyword in $keywords_articles
     return map {$keyword/spip:id_article : $keyword/spip:id_mot => fn:string()},
     map { 'duplicates': 'combine' }
    )

  (: construit une map clé-valeur avec id-keyword keyword :)
  let $Keywords := db:open('sens-public')//spip:spip_mots
  (: return $Keywords :)
  let $mapKeywords := map:merge(
    for $keyword in $Keywords
     return map {$keyword/spip:id_mot : $keyword/spip:titre => fn:string()},
     map { 'duplicates': 'combine' }
  )

  for $ref in $refs
  return
    let $idArticle := map:get($ref, 'num')
    let $article := db:open('sens-public')//spip:spip_articles[spip:id_article = $idArticle]
    
    let $ref := map:put( $ref, 'rubrique', map:get( $rubriques, $article/spip:id_rubrique/text()))
    let $ref := if ($article/spip:id_rubrique/text() = '109') 
                then map:put( $ref, 'issue', map:get($ref, 'num'))
                else map:put( $ref, 'issue', getIssue($article/spip:id_article/text())[1] )
    let $file := map:get($ref, 'num') || '-article' || '.xml'
    let $keywords := array { 
                      for $idKeyword in $mapArticleKeyword($idArticle)
                      return $mapKeywords($idKeyword)
                     }
    let $article := getArticle($article, $ref, $keywords)
    let $issue := map:get($ref, 'issue')
    let $article := if ($issue) then functx:remove-attributes($article, ('horstheme')) else functx:remove-attributes($article, ('idref'))
    let $annee := $article//annee
    return file:write($pathgitlab || $annee || '/' || $file, $article, map { 'method' : 'xml', 'indent' : 'yes', 'omit-xml-declaration' : 'no'})
};


(:~
 : This function builts the article content
 : @param $article the SPIP article
 : @param $ref the article references (id, num, vol, n)
 : @return an xml erudit article segment
 :
 : @todo solve the corps direct constructor by working on getRestruct
 : @todo define ordseq
 :)
declare function getArticle( $article as element(), $ref as map(*), $keywords as array(*) ) as element() {
  let $content := getContent($article/spip:texte, map{ '':'' })
  let $corps := <corps>{ getRestruct(getCleaned($content)) }</corps>
  let $biblio := getBiblio($content)
  let $grnote := getNote($content)
  let $liminaire := getLiminaire($article, $ref, $keywords)
  let $admin := getAdmin($article, $corps, $biblio, $grnote, $ref, $keywords)
  let $typeart := getTypeart(map:get( $ref, 'rubrique'))
  let $issue := map:get($ref, 'issue')
  let $idref := if ($issue) then ( 'th' || $issue ) else ()
  let $horstheme := if ($issue) then () else ("oui")
  let $ordseq := map:get($ref, 'n')
(: idproprio="{map:get($ref, 'id')}" :)
(: on conserve l'id article Erudit vide pour livraison Erudit:)
  return
    <article
      xmlns="http://www.erudit.org/xsd/article"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xsi:schemaLocation="http://www.erudit.org/xsd/article http://www.erudit.org/xsd/article/3.0.0/eruditarticle.xsd"
      qualtraitement="complet"
      idproprio="" 
      typeart="{$typeart}"
      lang="{fn:data($article/spip:lang)}"
      idref="{$idref}"
      horstheme="{$horstheme}"
      ordseq="{$ordseq}">{
        $admin,
        $liminaire,
        $corps,
        <partiesann lang="{fn:data($article/spip:lang)}">{(
          $biblio,
          $grnote
        )}</partiesann>
    }</article>
};


(:~
 : ~:~:~:~:~:~:~:~:~
 : 3 functx functions
 : ~:~:~:~:~:~:~:~:~
 :)

declare function functx:remove-attributes
  ( $elements as element()* ,
    $names as xs:string* )  as element() {

   for $element in $elements
   return element
     {fn:node-name($element)}
     {$element/@*[fn:not(functx:name-test(fn:name(),$names))],
      $element/node() }
 } ;
 
declare function functx:name-test
  ( $testname as xs:string? ,
    $names as xs:string* )  as xs:boolean {

$testname = $names
or
$names = '*'
or
functx:substring-after-if-contains($testname,':') =
   (for $name in $names
   return fn:substring-after($name,'*:'))
or
fn:substring-before($testname,':') =
   (for $name in $names[fn:contains(.,':*')]
   return fn:substring-before($name,':*'))
 } ;

declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (fn:contains($arg,$delim))
   then fn:substring-after($arg,$delim)
   else $arg
 } ;


(:~
 : This function gets the biblio
 : @param $content the content to parse
 : @return an erudit
 :)
declare function getBiblio($content as element()) {
    for $biblio in $content//grbiblio
    return copy $biblio := $biblio
      modify for $refbiblio in $content//grbiblio/biblio/following::para
      return insert node <refbiblio>{ $refbiblio/alinea/node() }</refbiblio> into $biblio/biblio
    return $biblio
};

(:~
 : This function gets the typeart
 : @param $rubrique the article's rubrique to be tested
 : @return the restricted type of article according to Erudit Schema
 :)
declare function getTypeart($rubrique as item()) {
    if			($rubrique = "Essai") 	then "article"
    else if ($rubrique = "Lecture") then "compterendu"
    else																 "autre"
};


(:~
 : This function get the notes
 : @param $content the content to parse
 : @return an erudit
 :)
declare function getNote($content as element()) {
  for $grnote in $content//grnote
  return copy $grnote := $grnote
        modify
          for $note in $content//note
          return insert node $note into $grnote
        return $grnote
};

(:~
 : This function
 : @param $content the content to parse
 : @return an erudit
 :)
declare function getCleaned($content as element()) {
  let $childs := $content/node()[. instance of element()]
  let $positions :=
    for $s in $content/(grnote | grbiblio)
    return functx:index-of-node($childs, $s)
  let $first := $positions[1]
  return copy $content := $content
    modify
      for $n in $content/*[fn:position() >= $first]
      return delete node $n
    return $content
};

(:~
 : This function
 : @param $content the content to parse
 : @return an
 :)
declare function getRestruct($element as element()) {
  let $childs := $element/node()[. instance of element()]
  let $positions :=
    for $s in $element/*[1] | $element/titre
    return functx:index-of-node($childs, $s)
  return partition($positions, $childs)
};


(:~
 : This function built the article metadata
 : @param $article the SPIP article
 : @param $ref the article’s references
 : @return the admin xml erudit element
 :
 : @todo check if word count include notes etc.
 : @todo add numero id <numero id="approchesind02027">
 :)
(: <numero id="{ map:get($ref, 'vol') }"> :)
(: on conserve numero/@id vide pour Erudit :)
declare function getAdmin( $article as element(), $corps, $biblio, $grnote, $ref as map(*), $keywords as array(*) ) as element() {
    <admin>
      <infoarticle>
        { getDescripteurs($article, $ref, $keywords) }
        <nbpara>{ fn:count($corps//para) }</nbpara>
        <nbmot>{ functx:word-count(fn:string($corps)) }</nbmot>
        <nbfig>{ fn:count($corps//figure) }</nbfig>
        <nbtabl>{ fn:count($corps//tableau) }</nbtabl>
        <nbimage>{ fn:count($corps//image) }</nbimage>
        <nbaudio>{ fn:count($corps//audio) }</nbaudio>
        <nbvideo>{ fn:count($corps//video) }</nbvideo>
        <nbrefbiblio>{ fn:count($biblio//refbiblio) }</nbrefbiblio>
        <nbnote>{ fn:count($grnote//note) }</nbnote>
      </infoarticle>
      <revue id="sp02131" lang="fr">
        <titrerev>Sens public</titrerev>
        <titrerevabr>sp</titrerevabr>
        <idissnnum>2104-3272</idissnnum>
        { getDirector($article, $ref), getRedacteurchef($article, $ref) }
      </revue>
      
      <numero id=""> 
        <pub>
          <annee>{ getDate($article, 4) }</annee>
        </pub>
        <pubnum>
          <date typedate="publication">{ getDate($article, 10) }</date>
        </pubnum>
        { getTheme($article, $ref) }
      </numero>
      <editeur>
        <nomorg>Département des littératures de langue française</nomorg>
      </editeur>
      <prod>
        <nomorg>Sens public</nomorg>
      </prod>
      <prodnum>
        <nomorg>Sens public</nomorg>
      </prodnum>
      <diffnum>
        <nomorg>Sens public</nomorg>
      </diffnum>
      <schema nom="Erudit Article" version="3.0.0" lang="fr"/>
      <droitsauteur>Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) <nomorg>Sens-Public</nomorg>, 2015</droitsauteur>     
    </admin>
};

(:~
 : this function get descriptors
 : @param $article the SPIP article
 : @param $ref the article’s references
 : @return the grDescripteur XML erudit element
 :
 : todo : ne pas prendre les mots-clé admin
 :)
declare function getDescripteurs( $article as element(), $ref as map(*), $keywords as array(*) ) as element()* {
let $descripteurs :=
  (: for $id in db:open('sens-public')//spip:spip_mots_articles[spip:id_article = $article/spip:id_article]/spip:id_mot
    let $mot := db:open('sens-public')//spip:spip_mots[spip:id_mot = $id] :)

  for $mot at $num in 1 to array:size($keywords)
    let $entry := $local:groupes/sp:list/sp:entry
  return if ( $keywords($mot) = fn:data($entry/sp:label))
    then <descripteur>{ fn:data($entry[fn:data(sp:label) = $keywords($mot)]/sp:term) }</descripteur> 
    else ()
return if ($descripteurs)
  then <grdescripteur lang="fr" scheme="http://rameau.bnf.fr">{$descripteurs}</grdescripteur>
  else ()
};

(:~
 : This function get the publication’s director
 : @param $article the SPIP article
 : @param $ref the article’s references
 : @return the XML erudit directeur element for each director by dates
 :)
declare function getDirector( $article as element(), $ref as map(*) ) as element()* {
let $directorsByDates := fn:doc($local:base || 'directors.xml')
let $date := fn:substring($article/spip:date, 1, 10) cast as xs:date
for $director in $directorsByDates/sp:directors/sp:director
  where $date > ($director/sp:date/@from cast as xs:date) and $date < ($director/sp:date/@to cast as xs:date)
  return
    <directeur sexe="{ $director/sp:sexe/text() }">
      <nompers>
        <prenom>{ $director//sp:forename/text() }</prenom>
        <nomfamille>{ $director//sp:surname/text() }</nomfamille>
      </nompers>
    </directeur>
};

(:~
 : This function get the issue editor
 : @param $article the SPIP article
 : @param $ref the article’s references
 : @return the redacteurchef xml erudit element
 :
 : @todo factorize with getAuteurs
 : @todo sex and fonction
 : @todo add link with theme idrefs="th1"
 :)
declare function getRedacteurchef( $article as element(), $ref as map(*) ) as element()* {
  (: let $id := $article/id_article :)
  let $issue := map:get($ref, 'issue')
  let $theme := 'th' || $issue
  for $authorsId in db:open('sens-public')//spip:spip_auteurs_articles[spip:id_article = $issue]/spip:id_auteur
    return
      for $author in db:open('sens-public')//spip:spip_auteurs[spip:id_auteur = $authorsId]/spip:nom
      let $name := fn:tokenize($author/text(), '\*')
      return
        <redacteurchef typerc="invite" sexe="masculin">
        { if ($theme != '') then attribute idrefs { $theme } else () }
          <fonction lang="fr"/>
            <nompers>
              <prenom>{ $name[2] }</prenom>
              <nomfamille>{ $name[1] }</nomfamille>
            </nompers>
        </redacteurchef>
};

declare function getDate($article, $nb) {
  fn:substring($article/spip:date, 1, $nb)
};

(:~
 : This function get the issue
 : @param $id the article ids
 : @return a sequence of issues ids
 :
 : @todo don’t return a seq when one id is given
 :)
declare function getIssue( $idSeq as xs:string* ) as xs:string* {
  for $item in $idSeq
  return
    let $dossiers := db:open('sens-public')//spip:spip_articles[spip:id_rubrique = '109']
    return
      for $lien in $dossiers//spip:a
      let $regex := '(.*?)spip\.php\?article' || $item
      where fn:matches($lien/@href, $regex)
        return $lien/ancestor::spip:spip_articles/spip:id_article/text()
};

(:~
 : This function gets the Theme
 : @param $article the article to process
 : @param $ref the article’s references
 : @return an XML erudit grTheme element
 :
 : @todo add a treatment for theme mixed content
 :)
declare function getTheme( $article as element(), $ref as map(*) ) as element() {
  let $issue := map:get($ref, 'issue')
  let $theme := db:open('sens-public')/spip:SPIP/spip:spip_articles[spip:id_article=$issue]/spip:titre
  return (if ($issue) then (
    <grtheme id="{ 'th' || $issue }" >
         <theme>{$theme/text()}</theme>
    </grtheme>
  )
  else (
    <grtheme>
         <theme>Varia</theme>
    </grtheme>    
  )
)
   
};

(:~
 : ~:~:~:~:~:~:~:~:~
 : text serialization
 : ~:~:~:~:~:~:~:~:~
 :)


(:~
 : This function get the liminaire
 : @param $article the SPIP article
 : @return the liminaire xml erudit element
 :)
declare function getLiminaire( $article as element(), $ref as map(*), $keywords as array(*)  ) as element() {
  <liminaire>
    { getTitre($article, $ref),
      getAuteurs($article),
      getResume($article),
      getMotclef($article, $ref, $keywords) }
  </liminaire>
};

(:~
 : This function get the title
 : @param $article the SPIP article
 : @return the titre xml erudit element
 :
 : @todo regex for unmarked sub-titles
 :)
declare function getTitre($article as element(), $ref as map(*) ) as element() {
  let $issue := map:get($ref, 'issue')
  let $theme := if (map:get($ref, 'rubrique')='Sommaire dossier') 
                then $article/spip:titre/text()
                else if ($issue)
                then db:open('sens-public')/spip:SPIP/spip:spip_articles[spip:id_article=$issue]/spip:titre/text()
                else ("Varia")
  let $typeart := map:get( $ref, 'rubrique')
  return
  <grtitre>
    <surtitre>{ $theme }</surtitre>
    <surtitre2>{ $typeart }</surtitre2>
    <titre>{ passthru($article/spip:titre, map{ '':'' }) }</titre>
    { if ( $article/spip:soustitre != () )
        then <sstitre>{ passthru($article/spip:soustitre, map{ '':'' }) }</sstitre>
        else () }
  </grtitre>
};

(:~
 : this function get the authors
 : @param $article the SPIP article to process
 : @return the grauteur xml erudit element
 :
 :)
declare function getAuteurs($article as element() ) as element() {
  <grauteur>{
    for $id in db:open('sens-public')//spip:spip_auteurs_articles[spip:id_article = $article/spip:id_article]/spip:id_auteur
    return
      for $auteur in db:open('sens-public')//spip:spip_auteurs[spip:id_auteur = $id]/spip:nom
      let $nom := fn:tokenize($auteur/text(), '\*')
      return
        <auteur id="{ 'spAuthor' || $id }">
          <nompers>
            <prenom>{ $nom[2] }</prenom>
            <nomfamille>{ $nom[1] }</nomfamille>
          </nompers>
        </auteur>}
  </grauteur>
};

(:~
 : this function get the abstract
 : @param $article the SPIP article
 : @return a sequence of resume xml erudit element for various languages
 : @issue casts abstract to xs:string and ignores tags if appears there ({{Mots-clés:}})
 :)
declare function getResume($article as element() ) as element()* {
  let $regex := '\{\{(.*?)\s*?:?\}\}\s*?(.*)'
  let $ana := fn:analyze-string($article/spip:descriptif, $regex)
  for $match in $ana/fn:match
return
  switch ($match)
  case ($match[fn:contains(fn:group[@nr='1'], "Résumé")])
    return <resume lang="fr">
             <alinea>{$match/fn:group[@nr='2']/text()}</alinea>
           </resume>
  case ($match[fn:contains(fn:group[@nr='1'], "Abstract")])
    return <resume lang="en">
             <alinea>{$match/fn:group[@nr='2']/text()}</alinea>
           </resume>
  case ($match[fn:contains(fn:group[@nr='1'], "Resumen")])
    return <resume lang="de">
             <alinea>{$match/fn:group[@nr='2']/text()}</alinea>
           </resume>
  default return ()
};

(:~
 : this function get the tags
 : @param $article the SPIP article
 : @return a sequence of grmotclef xml erudit element for various languages
 : @todo group by language fn:analyze-string($string, '\[([a-z]{2})\](.*?)')
 :)
declare function getMotclef( $article as element(), $ref as map(*), $keywords as array(*)  ) as element() {
  let $issue := map:get($ref, 'issue')
  let $theme := db:open('sens-public')/spip:SPIP/spip:spip_articles[spip:id_article=$issue]/spip:titre
  let $lang := "fr"
  return
  <grmotcle lang="{$lang}">
    {
      for $mot at $num in 1 to array:size($keywords)
      return if (fn:starts-with($keywords($mot), '['))
        then <motcle>{ getMultiKeywords($keywords($mot), $lang) }</motcle>
        else if ($keywords($mot) = $theme/text()) then () 
        else if ($keywords($mot) = "focus" ) then () 
        else if ($keywords($mot) = "focuscreation" ) then () 
        else if ($keywords($mot) = "essais" ) then () 
        else <motcle>{ $keywords($mot) }</motcle>
    }
  </grmotcle>
};

(:~
 : this function returns a map of langage:keywords
 : @param a multi-language keyword : "[fr]Cinéma[en]Cinema[it]Cinema"
 : @return a map of items with language:keywords : "fr: Cinéma"
 :)
declare function getMultiKeywords( $text as xs:string, $lang as xs:string ) as xs:string {
  let $tokenizedText := array {fn:tokenize($text,"\[|\]")}
  let $sizeLoop := array:size($tokenizedText) idiv 2 
  let $mapLangKeyw := map:merge(
    for $num in 1 to $sizeLoop
    return map{ $tokenizedText($num*2) : $tokenizedText($num*2+1)}
  )
  return $mapLangKeyw($lang)
};

(:~
 : this function serialize text in xml erudit
 : @param a sequence of node
 : @options option for serialization
 : @return a sequence of items in (a nearby) xml erudit
 :)
declare function getContent( $nodes as node()*, $options as map(*) ) as item()* {
  dispatch($nodes, $options)
};


(:~
 : this function dispatches the treatment of the XML document
 :)
declare function dispatch($node as node()*, $options as map(*)) as item()* {
  typeswitch($node)
    case text() return $node
    case element(spip:texte) return texte($node, $options)
    case element(spip:chapo) return chapo($node, $options)
    case element(spip:div) return div($node, $options)
    case element(spip:h1) return h1($node, $options)
    case element(spip:h2) return h2($node, $options)
    case element(spip:h3) return h3($node, $options)
    case element(spip:h4) return h4($node, $options)
    case element(spip:p) return p($node, $options)
    case element(spip:blockquote) return blockquote($node, $options)
    case element(spip:cite) return cite($node, $options)
    case element(spip:ul) return ul($node, $options)
    case element(spip:li) return li($node, $options)
    case element(spip:a) return a($node, $options)
    case element(spip:em) return em($node, $options)
    case element(spip:strong) return strong($node, $options)
    case element(spip:i) return i($node, $options)
    case element(spip:sup) return sup($node, $options)
    case element(spip:span) return span($node, $options)
    case element(spip:img) return img($node, $options)
    case element(spip:figure) return figure($node, $options)
    case element(spip:audio) return audio($node, $options)
    case element(spip:br) return br($node, $options)
    default return passthru($node, $options)
};

(:~
 : this function pass through child nodes (xsl:apply-templates)
 :)
declare function passthru($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return dispatch($node, $options)
};

(:~
 : ~:~:~:~:~:~:~:~:~
 : erudit textstructure
 : ~:~:~:~:~:~:~:~:~
 :)

declare function texte($node as element(spip:texte)+, $options as map(*)) {
  <corps>{ if ($node/@xml:id) then attribute id { $node/@xml:id } else (),
    passthru($node, $options)}</corps>
};

(: todo what ? :)
declare function chapo($node as element(spip:chapo)+, $options as map(*)) {
  ()
};

declare function div($node as element(spip:div)+, $options as map(*)) {
  <section>
    { if ($node/@xml:id) then attribute id { $node/@xml:id } else (),
    passthru($node, $options)}
  </section>
};

declare function h1($node as element(spip:h1)+, $options as map(*)) {
  <titre>{ passthru($node, $options) }</titre>
};

(: @todo treat titles level :)
declare function h2($node as element(spip:h2)+, $options as map(*)) {
  <titre2>{ passthru($node, $options) }</titre2>
};

declare function h3($node as element(spip:h3)+, $options as map(*)) {
  <titre3>{ passthru($node, $options) }</titre3>
};

declare function h4($node as element(spip:h4)+, $options as map(*)) {
  <titre4>{ passthru($node, $options) }</titre4>
};

(: @todo alinea with br :)
(: @issue bug with multiple p notes ex 1139, note 1 :)
declare function p($node as element(spip:p)+, $options as map(*)) {
  switch ($node)
  case ( $node/spip:* instance of element(spip:img) and fn:not($node/text()[fn:normalize-space(.) != '']) ) return passthru($node, $options)
  case ( $node/spip:* instance of element(spip:figure) and fn:not($node/text()[fn:normalize-space(.) != '']) ) return passthru($node, $options)
  case ( $node/spip:* instance of element(spip:audio) and fn:not($node/text()[fn:normalize-space(.) != '']) ) return passthru($node, $options)
  case ( $node/spip:* instance of element(spip:blockquote) and fn:not($node/text()[fn:normalize-space(.) != '']) ) return passthru($node, $options)
  case ( $node/spip:* instance of element(spip:cite) and fn:not($node/text()[fn:normalize-space(.) != '']) ) return passthru($node, $options)
  case ($node[fn:normalize-space(.)='']) return ()
  case ($node[fn:normalize-space(.)='Bibliographie'])
    return
      <grbiblio>
        <biblio/>
      </grbiblio>
  case ($node[fn:normalize-space(.)='Notes']) return
      <grnote/>
  case ($node[spip:a[fn:ends-with(@href, 'anc')]]) return
    <note id="{$node/spip:a/@name}">{
           (<no>{ passthru($node/spip:a[1], $options) }</no>,
           <alinea>{ passthru($node, $options) }</alinea>
         )
         }</note>
  case ($node[parent::spip:li]) return <alinea>{ passthru($node, $options) }</alinea>
  case ($node[preceding-sibling::spip:a[fn:ends-with(@href, 'anc')]]) return
    <alinea>{ passthru($node, $options) }</alinea>
  default return
    <para>
      <alinea>{ passthru($node, $options) }</alinea>
    </para>
};

(: @todo refine :)
declare function blockquote($node as element(spip:blockquote)+, $options as map(*)) {
  <bloccitation><alinea>{ passthru($node, $options) }</alinea></bloccitation>
};

(: ajout d'une fonction cite() qui nécessitera un post-traitement manuel :)
declare function cite($node as element(spip:cite)+, $options as map(*)) {
  switch ($node)
  case ($node[parent::spip:blockquote]) return passthru($node, $options)
  case ($node[parent::spip:p]) return<citation>{passthru($node, $options)}</citation>
  default return passthru($node,$options)

};

declare function ul($node as element(spip:ul)+, $options as map(*)) {
  <listenonord signe="disque">{ passthru($node, $options) }</listenonord>
};

declare function li($node as element(spip:li)+, $options as map(*)) {
  <elemliste>{ passthru($node, $options) }</elemliste>
};

(:~
 : ~:~:~:~:~:~:~:~:~
 : erudit inline
 : ~:~:~:~:~:~:~:~:~
 :)

declare function a($node as element(spip:a)+, $options as map(*)) {
  switch ($node)
  case ($node[fn:ends-with(@href, 'sym')]) return <renvoi idref="{fn:substring-after($node/@href, '#')}" typeref="note">{ fn:data($node) }</renvoi>
  case ($node[fn:ends-with(@href, 'anc')]) return ()
  case ($node[fn:not(@href)]) return ()
  default return <liensimple xlink:type="simple" xlink:href="{$node/@href}">{passthru($node, $options)}</liensimple>
  
};

(: let $test := <a name='coucou'>coucou</a>
return if ($test[not(@href)]) then "pas de href" else "y a un href"
 :)

(: @todo a[1] is potentially subject to bug :)
declare function em($node as element(spip:em)+, $options as map(*)) {
  switch ($node)
  case ($node/spip:span[1]/spip:a[1][fn:ends-with(@href, 'sym')]) return passthru($node, $options)
  case ($node/spip:a[1][fn:ends-with(@href, 'sym')]) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = ' ']) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = '']) return ()
  default return <marquage typemarq="italique">{ passthru($node, $options) }</marquage>
};

declare function i($node as element(spip:i)+, $options as map(*)) {
  switch ($node)
  case ($node/spip:span[1]/spip:a[1][fn:ends-with(@href, 'sym')]) return passthru($node, $options)
  case ($node/spip:a[1][fn:ends-with(@href, 'sym')]) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = ' ']) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = '']) return ()
  default return <marquage typemarq="italique">{ passthru($node, $options) }</marquage>
};

declare function strong($node as element(spip:strong)+, $options as map(*)) {
  switch($node)
  case ($node[fn:normalize-space(.) = ' ']) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = '']) return ()
  default return <marquage typemarq="gras">{ passthru($node, $options) }</marquage>
};

declare function sup($node as element(spip:sup)+, $options as map(*)) {
  switch ($node)
  case ($node[fn:ends-with(@href, 'sym')]) return passthru($node, $options)
  case ($node[fn:normalize-space(.) = ' ']) return ()
  case ($node[fn:normalize-space(.) != '']) return <exposant>{ passthru($node, $options) }</exposant>
  default return ()
};

declare function span($node as element(spip:span)+, $options as map(*)) {
  switch ($node)
  case ($node[@rend='italic' or @rend='it']) return
    <marquage typemarq="italique">{ passthru($node, $options) }</marquage>
  default return passthru($node, $options)
};


(: @todo other elements available in erudit xml :)
declare function img($node as element(spip:img)+, $options as map(*)) {
  let $regex := 'IMG/(\w){3}/'
  let $imageName := functx:substring-after-last-match($node/@src, $regex)
  let $figcaption := $node/@title
  return
  <figure>
    { if ($figcaption)
      then <legende lang="fr">
             <alinea>{$figcaption}</alinea>
           </legende>
      else () }
    <objetmedia flot="bloc">
      <image id="{$imageName}" typeimage="figure" xlink:type="simple">{
        if ($figcaption) then attribute desc {$figcaption} else ()
      }</image>
    </objetmedia>
  </figure>
};

declare function figure($node as element(spip:figure)+, $options as map(*)) {
  <figure>
    { if ($node/spip:figcaption)
      then <legende lang="fr">
             <alinea>{$node/spip:figcaption/text()}</alinea>
           </legende>
      else () }
    <objetmedia flot="bloc">
      <image id="{$node/spip:img/@src}" typeimage="figure" xlink:type="simple"/>
    </objetmedia>
  </figure>
};

declare function audio($node as element(spip:audio)+, $options as map(*)) {
  let $regex := '\[(.*)-&gt;http://www.sens-public.org/IMG/(\w{3})/(.*)\]'
  let $alt := fn:analyze-string($node, $regex)//fn:group[@nr="1"]/text() (: the file desc :)
  let $dir := fn:analyze-string($node, $regex)//fn:group[@nr="2"]/text() (: the file dir :)
  let $file := fn:analyze-string($node, $regex)//fn:group[@nr="3"]/text() (: the file name :)
  return
    <objet typeobj="audio">
      <objetmedia flot="bloc">
        <audio id="{$file}"/>
      </objetmedia>
  </objet>
};

(: @todo create alinea :)
declare function br($node as element(spip:br), $options as map(*)) {
  ()
};

(:~
 : ~:~:~:~:~:~:~:~:~
 :utilities
 : ~:~:~:~:~:~:~:~:~
 :)

(:~
 : This function gives an index of nodes
 : @source http://www.xqueryfunctions.com/xq/functx_index-of-node.html
 :)
declare function functx:index-of-node($nodes as node()* ,
$nodeToFind as node() )  as xs:integer*
{
  for $seq in (1 to fn:count($nodes))
  return $seq[$nodes[$seq] is $nodeToFind]
};

(:~
 : This function recursively calculate the start elements with the other elements between as childs.
 : Take the first two indices of $positions and create a section element with the elements of $elements with positions between these two indices.
 : Then remove the first index of $position and do the recursive call.
 : @param $positions starting element indices
 : @param $elements content to process
 : @return section elements with childs
 : @source http://stackoverflow.com/questions/6865667/xpath-flat-hierarchy-and-stop-condition
:)
declare function partition($positions as xs:integer*, $elements as element()*) as element()* {
  let $nbSections := fn:count($positions)
  return
    if($nbSections gt 1)
    then (
      let $first := $positions[1]
      let $second := $positions[2]
      let $rest := fn:subsequence($positions, 2)
      return ( element section1 { fn:subsequence($elements, $first, $second - $first)}, partition($rest, $elements) )
    )
    else if($nbSections eq 1)
    then ( element section1 { fn:subsequence($elements, $positions[1]) } )
    else ()
};

(:~
 : This function counts words
 : @param $arg a string to proceed
 : @return the number of words in a string
 : @source http://www.xqueryfunctions.com/xq/functx_word-count.html
 :)
declare function functx:word-count
  ( $arg as xs:string? )  as xs:integer {

   fn:count(fn:tokenize($arg, '\W+')[. != ''])
 };

(:~
 : This function returns a deepcopy
 : @param $element elements to process
 : @return a deep copy of the element and all sub-elements
 :)
declare function copy($element as element()) as element() {
   element {fn:node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
               if ($child instance of element())
                 then copy($child)
                 else $child
      }
};

(:~
 : This function removes empty elements
 : @param $node node to process
 : @return a deep copy without empty elements
 : @source http://stackoverflow.com/questions/32188696/xquery-omitting-empty-elements-during-a-transformation
 :)
declare function removeNilled($node as node()) as node()? {
  typeswitch($node)
  case document-node() return document {
      for $child in $node/node()
      return removeNilled($child) }
  case element() return
    if($node/node())
      then element { fn:node-name($node) }
        { $node/attribute(),
          for $child in $node/node()
          return removeNilled($child) }
      else()
  default return $node
};

declare function functx:substring-after-last-match
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {

   fn:replace($arg,fn:concat('^.*',$regex),'')
 };

(: construit une map clé-valeur avec id-article id.s-auteur.s :)
let $auteurs_articles := db:open('sens-public')//spip:spip_auteurs_articles
let $mapArticleAuteur := map:merge(
  for $article in $auteurs_articles
   return map {$article/spip:id_article : $article/spip:id_auteur => fn:string()},
   map { 'duplicates': 'combine' }
  )

(: construit une map clé-valeur avec id-auteur nom*prénom :)
let $auteurs_articles := db:open('sens-public')//spip:spip_auteurs
let $mapAuteurs := map:merge(
  for $article in $auteurs_articles
   return map {$article/spip:id_auteur : $article/spip:nom => fn:string()},
   map { 'duplicates': 'combine' }
  )



(:~
 : This fuction gets the articles references
 : @return a map sequence with the article references from the identifiants.xml file
 : @rmq change [1] to the volume you want to transform
 :)
(: let $doc := $local:base || 'identifianttest.xml' :)
let $doc := '/home/nicolas/gitlab/senspublic/data/phase1/articleEN/identifiantsEchantillon2.xml'
let $refs := for $article in fn:doc($doc)//*:article
return map {
  'id' : fn:data($article/@id),
  'num' : fn:data($article),
  'vol' : fn:data($article/parent::*/@id),
  'n' : fn:data($article/@n)
  }

return writeArticles($refs)
