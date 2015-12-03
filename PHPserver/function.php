<?php
//Valid String POST / GET / REQUEST
function inputSecurity($validate=null) {
    if ($validate == null) {
        foreach ($_REQUEST as $key => $val) {
            if (is_string($val)) {
                $_REQUEST[$key] = htmlentities($val);
            } else if (is_array($val)) {
                $_REQUEST[$key] = inputSecurity($val);
            }
        }
        foreach ($_GET as $key => $val) {
            if (is_string($val)) {
                $_GET[$key] = htmlentities($val, ENT_QUOTES, 'UTF-8');
            } else if (is_array($val)) {
                $_GET[$key] = inputSecurity($val);
            }
        }
        foreach ($_POST as $key => $val) {
            if (is_string($val)) {
                $_POST[$key] = htmlentities($val, ENT_QUOTES, 'UTF-8');
            } else if (is_array($val)) {
                $_POST[$key] = inputSecurity($val);
            }
        }
    } else {
        foreach ($validate as $key => $val) {
            if (is_string($val)) {
                $validate[$key] = htmlentities($val, ENT_QUOTES, 'UTF-8');
            } else if (is_array($val)) {
                $validate[$key] = inputSecurity($val);
            }
            return $validate;
        }
    }
}

function isEqual($key,$val){
  if(isset($key) AND $key == $val){
    $return = true;
  }
  else{
     $return = false;
     }
     return $return;
}
function notNull($key){
  if(isset($key) AND $key != ""){
    $return = true;
  }
  else{
     $return = false;
     }
     return $return;
}
function startsWith($haystack, $needle) {
    // search backwards starting from haystack length characters from the end
    return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}
?>
