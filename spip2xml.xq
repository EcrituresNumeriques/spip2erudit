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

declare default element namespace "http://spip.net/tagset/" ;
declare namespace functx = "http://www.functx.com";

declare function functx:replace-multi
  ( $arg as xs:string?, $changeFrom as xs:string*, $changeTo as xs:string* )  as xs:string? {
    if (count($changeFrom) > 0)
      then functx:replace-multi(
        replace($arg, $changeFrom[1],
        functx:if-absent($changeTo[1],'')),
        $changeFrom[position() > 1],
        $changeTo[position() > 1])
      else $arg
};

declare function functx:if-absent( $arg as item()*, $value as item()* )  as item()* {
      if (exists($arg)) then $arg else $value
};


let $arg := "text &lt;test"
let $from := ('&lt;') 
let $to := ('<')
return functx:replace-multi($arg, $from, $to)