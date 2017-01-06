# Révision éditoriale des articles

Après la migration automatisée, opérations à effectuer pour le contrôle éditorial des articles.

- contrôler la présence des résumés //resume
- contrôler la structure hiérarchique (section1 isolée //corps[count(section1)=1], lorsqu’il y a un traducteur le mettre à la fin.
- vérifier l’intégrité des notes (lorsque les notes débutent par un hyperlien, celui-ci a été supprimé) //partiesann/grnote/note 
- contrôler le nombre d’images dans chaque article fn:count(//figure)
- contrôle les tableaux
- Distinguer les articles en fonction de leur statut (article, compte-rendu, etc. attendre les valeurs d’Érudit) attribut @typeart sur <article>
- Vérifier la présence de la biblio

## à déterminer avec Marcello

- Repenser la question des numéros
- orthotypographique : ? ; ! etc.


- vérifier l’attribut de langue (article, partiesann et légendes des images et tableau) https://fr.wikipedia.org/wiki/Liste_des_codes_ISO_639-1
