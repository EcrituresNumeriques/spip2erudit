xquery version "3.1";

declare default function namespace 'local' ;
declare namespace csv = "http://basex.org/modules/csv";
declare namespace spip = "http://spip.net/tagset/" ;
declare namespace sp = "http://sens-public.org/sp/" ;

declare variable $local:base := file:base-dir() ;
declare variable $local:groupes := fn:doc($local:base || 'groupes.xml') ;

(: déclare les options pour le serialiseur CSV:)
let $options := map { 'separator': ';', 'header':"yes"}

(: ouvre la base XML:)
let $articles := db:open("sens-public")//spip:spip_articles

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
   let $tokenizedText := array { fn:tokenize($keyword/spip:titre => fn:string(),"\[|\]")}
   let $cleanedKeyword := if ( array:size($tokenizedText) = 1) 
                          then $tokenizedText(1) 
                          else $tokenizedText(3)
 return map {$keyword/spip:id_mot : $cleanedKeyword},
 map { 'duplicates': 'combine' }
)

(: démarre le script de construction d'un xml "à plat" qui sera parsé en CSV :)
let $toBeCsv :=  <articlesTb>{
  for $article in $articles
    let $id := $article/spip:id_article => fn:string()
    let $title := $article/spip:titre => fn:string()
    let $datePub := $article/spip:date => fn:string()
    let $dateMaj := $article/spip:maj => fn:string()
    let $dateModif := $article/spip:date_modif => fn:string()
    let $rubrique := $article/spip:id_rubrique => fn:string()
    let $auteurs := <auteurs>{
                      for $idAuteur in $mapArticleAuteur($id)
                      return "#" || fn:tokenize($mapAuteurs($idAuteur), "\*")[2] || " " || fn:tokenize($mapAuteurs($idAuteur), "\*")[1] 
                    }</auteurs>
    let $keywords := <keywords>{
                      for $idKeyword in $mapArticleKeyword($id)
                      return "#" || $mapKeywords($idKeyword)
                     }</keywords>
    let $director := <directeur>{
                      if (fn:tokenize($article/spip:date,'-')[1] <= "2011") then "Gérard Wormser" else "Marcello Vitali-Rosati"
    }</directeur>
  return 
  <article>
    <id>{$id}</id>
    <title>{$title}</title>
    <datePub>{$datePub}</datePub>
    <dateModif>{$dateModif}</dateModif>
    <dateMaj>{$dateMaj}</dateMaj>    
    <rubrique>{$rubrique}</rubrique>
    {$auteurs}
    {$keywords}     
    {$director}
  </article>

}  </articlesTb>

(:
  construit le csv général  
:)
let $output := csv:serialize($toBeCsv, $options)
return file:write-text("/home/nicolas/ownCloud/sensPublic/Base/SP20151007_ALL.csv", $output)


(: 
  requête sur un auteur
:)
(:
let $wormser := <wormers>{$toBeCsv/article[fn:contains(auteurs, "Wormser")]}</wormers>
let $output := csv:serialize($wormser, $options)
return file:write-text("/home/nicolas/ownCloud/sensPublic/Base/SP20151007_wormser.csv", $output)
:) 
 
