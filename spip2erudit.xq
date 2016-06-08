xquery version "3.0" ;

(:~
 : This module transforms SPIP XML export to erudit XML
 :
 : @version 0.3
 : @since 2015-11-04
 : @date 2016-05 
 : @author emchateau
 :
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
  for $ref in $refs
  return 
    let $article := db:open('sens-public')//spip:spip_articles[spip:id_article = map:get($ref, 'num')]
    let $ref := map:put( $ref, 'issue', getIssue($article/spip:id_article/text())[1] )
    let $file := map:get($ref, 'num') || '-article' || '.xml'
    let $article := getArticle($article, $ref)
    return file:write($path || $file, $article, map { 'method' : 'xml', 'indent' : 'yes', 'omit-xml-declaration' : 'no'})
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
declare function getArticle( $article as element(), $ref as map(*) ) as element() {
  let $content := getContent($article/spip:texte, map{ '':'' })
  let $corps := <corps>{ getRestruct(getCleaned($content)) }</corps>
  let $biblio := getBiblio($content)
  let $grnote := getNote($content)
  let $liminaire := getLiminaire($article)
  let $admin := getAdmin($article, $corps, $biblio, $grnote, $ref)
  return 
    <article
      xmlns="http://www.erudit.org/xsd/article" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xmlns:xlink="http://www.w3.org/1999/xlink" 
      xsi:schemaLocation="http://www.erudit.org/xsd/article http://www.erudit.org/xsd/article/3.0.0/eruditarticle.xsd" 
      qualtraitement="complet" 
      idproprio="{map:get($ref, 'id')}" 
      typeart="autre" 
      lang="fr" 
      ordseq="1">{ 
        $admin, 
        $liminaire, 
        $corps,
        <partiesann>{(
          $biblio,
          $grnote
        )}</partiesann>
    }</article>
};


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
declare function getAdmin( $article as element(), $corps, $biblio, $grnote, $ref as map(*) ) as element() {
    <admin>
      <infoarticle>
        <idpublic scheme="doi">null</idpublic>
        { getDescripteurs($article, $ref) }
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
      <revue id="sp01868" lang="fr">
        <titrerev>Sens public</titrerev>
        <titrerevabr>SP</titrerevabr>
        <idissnnum>2104-3272</idissnnum>
        { getDirector($article, $ref), getRedacteurchef($article, $ref) }
      </revue>
      <numero id="{ map:get($ref, 'vol') }">
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
      <histpapier>
        <alinea>néant</alinea>
      </histpapier>
      <schema nom="Erudit Article" version="3.0.0" lang="fr"/>
      <droitsauteur>Tous droits réservés © <nomorg>Sens-Public</nomorg>, 2015</droitsauteur>
    </admin>
};

(:~
 : this function get descriptors
 : @param $article the SPIP article
 : @param $ref the article’s references
 : @return the grDescripteur XML erudit element
 :)
declare function getDescripteurs( $article as element(), $ref as map(*) ) as element()* {
let $descripteurs := 
  for $id in db:open('sens-public')//spip:spip_mots_articles[spip:id_article = $article/spip:id_article]/spip:id_mot
    let $mot := db:open('sens-public')//spip:spip_mots[spip:id_mot = $id]
    let $entry := $local:groupes/sp:list/sp:entry
  return if ( fn:data($mot/spip:titre) = fn:data($entry/sp:label) ) 
    then <descripteur>{ fn:data($entry[fn:data(sp:label) = fn:data($mot/spip:titre)]/sp:term) }</descripteur> 
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
  return
   <grtheme id="{ 'th' || $issue }">
     <theme>{ $theme/text() }</theme>
   </grtheme>
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
declare function getLiminaire( $article as element() ) as element() {
  <liminaire>
    { getTitre($article),
      getAuteurs($article),
      getResume($article), 
      getMotclef($article) }
  </liminaire>
};

(:~
 : This function get the title
 : @param $article the SPIP article
 : @return the titre xml erudit element
 :
 : @todo regex for unmarked sub-titles
 :)
declare function getTitre($article as element() ) as element() {
  <grtitre>
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
declare function getMotclef( $article as element() ) as element() {
  <grmotcle lang="fr">
    {
      for $id in db:open('sens-public')//spip:spip_mots_articles[spip:id_article = $article/spip:id_article]/spip:id_mot
      let $mot := db:open('sens-public')//spip:spip_mots[spip:id_mot = $id]
      return if ($mot/spip:titre/spip:multi) 
        then let $mot := fn:tokenize($mot/spip:titre/spip:multi/text(), '\[[a-z]{2}\]') return <motcle>{ $mot[2] }</motcle>
        else <motcle>{ $mot/spip:titre/text() }</motcle>
    }
  </grmotcle>
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
  case ($node[fn:normalize-space(.)='Bibliographie']) 
    return 
      <grbiblio>
        <biblio/>
      </grbiblio>
  case ($node[fn:normalize-space(.)='Notes']) return 
      <grnote/>
  case ($node[spip:a[fn:contains(@href, 'anc')]]) return 
    <note id="{$node/spip:a/@name}">{
           (<no>{ passthru($node/spip:a[1], $options) }</no>, 
           <alinea>{ passthru($node, $options) }</alinea>
         )
         }</note>
  case ($node[parent::spip:li]) return <alinea>{ passthru($node, $options) }</alinea>
  case ($node[preceding-sibling::spip:a[fn:contains(@href, 'anc')]]) return 
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
  case ($node[fn:contains(@href, 'sym')]) return <renvoi idref="{fn:substring-after($node/@href, '#')}" typeref="note">{ fn:data($node) }</renvoi>
  case ($node[fn:contains(@href, 'anc')]) return ()
  default return <liensimple xlink:type="simple" xlink:href="{$node/@href}">{passthru($node, $options)}</liensimple>
};

(: @todo a[1] is potentially subject to bug :)
declare function em($node as element(spip:em)+, $options as map(*)) {
  switch ($node)
  case ($node/spip:span[1]/spip:a[1][fn:contains(@href, 'sym')]) return passthru($node, $options)
  case ($node/spip:a[1][fn:contains(@href, 'sym')]) return passthru($node, $options)
  default return <marquage typemarq="italique">{ passthru($node, $options) }</marquage>
};

declare function i($node as element(spip:i)+, $options as map(*)) {
  switch ($node)
  case ($node/spip:span[1]/spip:a[1][fn:contains(@href, 'sym')]) return passthru($node, $options)
  case ($node/spip:a[1][fn:contains(@href, 'sym')]) return passthru($node, $options)
  default return <marquage typemarq="italique">{ passthru($node, $options) }</marquage>
};

declare function strong($node as element(spip:strong)+, $options as map(*)) {
  <marquage typemarq="gras">{ passthru($node, $options) }</marquage>
};

declare function sup($node as element(spip:sup)+, $options as map(*)) {
  switch ($node)
  case ($node[fn:contains(@href, 'sym')]) return passthru($node, $options)
  case (fn:normalize-space($node) != '') return <exposant>{ passthru($node, $options) }</exposant>
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
  return
  <figure>
    { if ($node/@alt != '') 
      then <legende lang="fr">
             <alinea>{$node/@alt}</alinea>
           </legende>
      else () }
    <objetmedia flot="bloc">
      <image id="{$imageName}" typeimage="figure">{
        if ($node/@alt) then attribute desc {fn:string($node/@alt)} else ()
      }</image>
    </objetmedia>
  </figure>
};

declare function figure($node as element(spip:figure)+, $options as map(*)) {
  <figure>
    { if ($node/figcaption) 
      then <legende lang="fr">
             <alinea>{$node/figcaption/text()}</alinea>
           </legende>
      else () }
    <objetmedia flot="bloc">
      <image id="{$node/@src}" typeimage="figure"/>
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
 : This function give an index of nodes
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

(:~ 
 : This fuction gets the articles references
 : @return a map sequence with the article references from the identifiants.xml file
 : @rmq change [1] to the volume you want to transform
 :)
let $doc := $local:base || 'identifiants.xml'
let $refs := for $article in fn:doc($doc)//sp:article
return map { 
  'id' : fn:data($article/@id),
  'num' : fn:data($article),
  'vol' : fn:data($article/parent::sp:*/@id),
  'n' : fn:data($article/@n)
  }

return writeArticles($refs)