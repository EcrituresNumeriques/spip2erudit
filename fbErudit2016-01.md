# Retours d’Érudit (Hocine Chebab) du 14 décembre 2015

- plein-texte
- transmission des fichiers (pdf, images)
- système de nommage
- espace de nom
- délais de mise en production
- lien vers publication originale
- tt base ou fichiers CRSH


Nous vous remercions pour cet excellent travail, avant d’entrer dans l’analyse des fichiers fournis, je souhaite vous informer que Quinoa (application qui traite le contenu reçu par SFTP) n’est pas conçu pour traiter le corps du texte, les fichiers ont été traités avec le traitement minimal, toutefois nous avons pris en considération le balisage du corps du texte lors notre analyse :

Voici le lien pour visualiser le résultat du traitement : http://beta.erudit.org/revue/SP/2015/v/n/index.html?ticket=3e4f2a9dba51ad71ec148c9dd8d7da14

## Éléments que le schéma supporte (non utilisés par la plateforme) :

1. Éléments <descripteur> et <grdescripteur> (utilisation d’autorités) : présent dans le schéma érudit, mais on ne les utilise pas

@R OK, nous les utiliserons. Plaçons-nous en attendant l’information dans les tags ?

2. Éléments <nbpara>, <nbmot>, <nbfig>, <nbtabl>, <nbimage>, <nbaudio>, <nbvideo>, <nbrefbiblio>.

@R L’utilisation de ces éléments est requise pour la validité des fichiers


3. Ajouter un élément « id » au(x) thème(s) (attribut optionnel, mais toujours utilisé quand il y a un thème). L’id du thème (id=”th1”, id=”th2”), sert à lier le(s) thème(s) d’un numéro et les rédacteurs invités liés au thème (<redacteurchef typerc=”invite idref=”th1” sexe=”masculin”>. Permet d’identifier, au sommaire, les responsables du ou des thème(s).

Schéma érudit :
Dans le XML décrivant le numéro

Dans le XML de l’article, afin d’attribuer l’article à ce thème

@R Si la gestion des identifiants n’est pas assurée par l’application, disposez-vous d’un système de nommage particulier ?
Lien entre les rédacteurs invités et les thèmes (XML du numéro)
Pourquoi mettre les thèmes sur l’élément parent

Affichage au sommaire du ou des thèmes et des contributeurs associés  (http://www.erudit.org/revue/smq/1996/v21/n1/index.html)

@R revoir
Comment fait-on lorsque l’on ne dispose pas de numéro ?

4. Les informations sur la revue (rédaction, rédaction, éditeur, issn, isbn) et informations sur le numéro doivent être au sommaire (le(s) thème(s), le(s) rédacteur(s) invité(s)… )

Affichage sur Érudit :

Affichage obtenu avec les fichiers de Sens public :

@R Ok d’où vient l’absence de lien ?


5.       Élément <pubnum>, élément enfant <date> : dans le schéma EruditArticle on ajoute un attribut « typedate » avec la valeur « publication » (attribut optionnel)

@R OK


6. Élément <histpapier> à n’utiliser qu’au besoin :
Érudit (utilisation correcte) :

@R il n’y a pas vraiment d’historique en dehors de la publication.

7.       Ajouter un attribut « id » (optionnel dans le schéma érudit) et un élément <no> (optionnel dans le schéma érudit) aux sections et aux paragraphes afin de pouvoir les identifier :

@R pourquoi faire ? pas de gestion auto n° ?



8.       Ajouter un attribut « id » (optionnel dans le schéma érudit) aux éléments <renvoi> :
Érudit :

@R quelle utilité ? pas de gestion dans l’appli ?


9.       Ne pas mettre l’élément <renvoi> à l’intérieur d’un élément <exposant>, ce qui semble arriver pour certains renvois :
Sens Public :


@R yep


10.   Ne pas utiliser d’appel d’entité dans le texte
Sens Public XML :

@R yep

11.   À moins d’une demande exceptionnelle de la revue, il n’est pas nécessaire d’ajouter un élément <titre> à un élément <bibliographe> : le titre générique « Bibliographe » est généré automatiquement sur le site d’érudit. On ajouterait un élément titre si la revue demandait que la bibliographie porte un autre titre que celui-là.

Un titre sera ajouté aux divisions d’une bibliographie (élément <divbiblio>) si la bibliographie contient une ou des sous-section(s).


@R yep


12. Ajouter un attribut « id » aux éléments <refbiblio>
Érudit :

@R pourquoi faire ?


13. Ne pas ajouter un élément <titre> aux résumés. Le titre générique « Résumé » (« Abstract » en anglais et « Resumen » en espagnol) est généré automatiquement lorsqu’un élément <résume> est ajouté, il faudra ajouter la langue du résumé comme le montre la capture suivante :

@R yep


14. Le niveau de traitement des articles publiés avec Sens Public est minimal. Pourtant le site semble penser qu’il s’agit d’articles en traitement complet : les services de gauche offrent la possibilité de consulter le texte intégral, le plan de l’article, la liste des figures, etc. :
Érudit :

@R Discussion


15.   Les informations qui concernent les figures ou les tableaux devraient être à l’intérieur de l’élément <figure> ou <tableau> et non pas mis en forme à l’extérieur de ceux-ci :

@R yep


16.   Les fichiers ne sont pas nommés selon la convention

La nomenclature numérotée marque le lien entre les métadonnées et les manifestations de l'article (entre le fichier de métadonnées EruditArticle et le PDF). Par exemple, l'article "001-article.pdf" est associé aux métadonnées "001-article.xml". (L'information qui permet de retrouver l'article et son appartenance à un numéro de revue est assurée par les identifiants que l'on retrouve parmi les métadonnées.) ;

L'extension permet de déterminer s'il s'agit d'une manifestation de l'article en pdf ou le fichier xml de métadonnées.

Exemples :
- 001-article.xml : le fichier xml du modèle Erudit Article 3.0.0 de l'article numéro 001;
- 001-article.pdf : le fichier pdf de l'article numéro 001;
- 002-#article.xml : le fichier xml du modèle Erudit Article 3.0.0 de l'article numéro 002 qui doit être supprimé;


@R revoir


17.   L’entête du fichier xml est incomplet :
Dans l’entête des fichiers, il manque souvent le namesapce « xmlns:xsi=http://www.w3.org/2001/XMLSchema-instance »
Dans l’entête des fichiers, le namespace vers le schéma Erudit Article est parfois mal écrit. Il doit être comme tel : « xsi:schemaLocation=http://www.erudit.org/xsd/article http://www.erudit.org/xsd/article/3.0.0/eruditarticle.xsd »

@R OK


18.   L’id de l’élément « revue » est erroné dans tous les fichiers. Il doit être « sp01868 » au lieu de « spxx » pour Sens Public. Cet identifiant est unique pour cette revue.

@R ok

19.   Dans certains fichiers, l’élément « numero » n’a pas de « id ».

@R pourquoi faire
