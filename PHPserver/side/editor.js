$(document).ready(function () {
  //document.designMode = "on";
  //$("section#text").get(0).designMode = "on";
  drawParagraphe();
  yAxis = 0;
  $(".typeIn").on("click", function () {
    yAxis = $(this).attr("data-yAxis");
  });
  //Top Navigation
  $("#downloadXML").on("click",function(){
    window.location.href = 'xml.php';
  });

  //Metadata update
  $("#inputtitre").on("input",function(){
    $.post('acknoledge.php', {
        action: "meta",
        id_text: "1",
        text: $("#inputtitre").val(),
        field: "titre"
      }, "json")
      .done(function (data) {})
      .fail(function (d, textStatus, error) {
        console.error("getJSON failed, status: " + textStatus + ", error: " + error);
      })
      .always(function (d) {});
  });
    $("#inputsoustitre").on("input",function(){
    $.post('acknoledge.php', {
        action: "meta",
        id_text: "1",
        text: $("#inputsoustitre").val(),
        field: "soustitre"
      }, "json")
      .done(function (data) {})
      .fail(function (d, textStatus, error) {
        console.error("getJSON failed, status: " + textStatus + ", error: " + error);
      })
      .always(function (d) {});
  });
    $("#inputdescription").on("input",function(){
    $.post('acknoledge.php', {
        action: "meta",
        id_text: "1",
        text: $("#inputdescription").val(),
        field: "description"
      }, "json")
      .done(function (data) {})
      .fail(function (d, textStatus, error) {
        console.error("getJSON failed, status: " + textStatus + ", error: " + error);
      })
      .always(function (d) {});
  });

  //Enter trigger new paragraphe creation, putting all the text after the selector to go on the next paragraphe
  $("#text").on("input", function () {
    if (!drawParagraphe()) {
      //No change in the paragraphes, updating current selected
      updateParagraphe(yAxis);
    }
    $(".typeIn").unbind("click");
    $(".typeIn").on("click", function () {
      yAxis = $(this).attr("data-yAxis");
    });
  });

  function updateParagraphe(MyyAxis) {
    $.post('acknoledge.php', {
        action: "update",
        id_text: "1",
        text: $(".typeIn[data-yAxis=" + MyyAxis + "]").html(),
        yAxis: MyyAxis
      }, "json")
      .done(function (data) {})
      .fail(function (d, textStatus, error) {
        console.error("getJSON failed, status: " + textStatus + ", error: " + error);
      })
      .always(function (d) {        
    });
      var text = $(".typeIn[data-yAxis=" + MyyAxis + "]").html();
    if(text.startsWith("#h1#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("h1");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(4));
    }
    else if(text.startsWith("#h2#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("h2");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(4));
    }
    else if(text.startsWith("#h3#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("h3");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(4));
    }
    else if(text.startsWith("#nl#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("nl");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(4));
    }
    else if(text.startsWith("#l#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("l");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(3));
    }
    else if(text.startsWith("#p#")){
        $(".typeIn[data-yAxis=" + MyyAxis + "]").removeClass("h1 h2 h3 p nl l p").addClass("p");
        $(".typeIn[data-yAxis=" + MyyAxis + "]").html(text.substr(3));
    }
  }

  function drawParagraphe() {
    paragraphe = 0;
    lastyAxis = 0;
    offset = 0;
    toAdd = 0;
    offsetAdd = 0;
    $(".typeIn").each(function () {
      paragraphe++;
      //Check for new paragraphe
      if ($(this).attr("data-yAxis") == lastyAxis) {
        console.log("new paragraphe " + paragraphe);
        if (toAdd === 0) {
          toAdd = Number(paragraphe) - 1;
        }
        yAxis = paragraphe;
        offsetAdd++;
      } else {
        if ($(this).attr("data-yAxis") == paragraphe) {
          //same content
        } else if ($(this).attr("data-yAxis") > paragraphe) {
          //previous paragraphe got deleted
          if (offset == 0) {
            offset = Number($(this).attr("data-yAxis")) - paragraphe;
            $.post('acknoledge.php', {action: "remove",id_text: "1",offset: offset,start: paragraphe}, "json")
            .done(function (data) {})
            .fail(function (d, textStatus, error) {console.error("getJSON failed, status: " + textStatus + ", error: " + error);})
            .always(function (d) {});
            yAxis = paragraphe - 1;
            //console.log("REMOVE update paragraphe SET yAxis = yAxis - " + offset + " where yAxis > " + paragraphe + " AND id_text = 1");
          }
        } else if ($(this).attr("data-yAxis") < paragraphe) {
          //Previous paragraphe added
          if (offset == 0) {
            offset = paragraphe - Number($(this).attr("data-yAxis"));
            var start = Number(paragraphe) - 2;
            $.post('acknoledge.php', {action: "add",id_text: "1",offset: offset,start: start}, "json")
            .done(function (data) {})
            .fail(function (d, textStatus, error) {console.error("getJSON failed, status: " + textStatus + ", error: " + error);})
            .always(function (d) {});
            yAxis = start + 1;
            while (offset >= -1) {
              MyyAxis = start + offset;
              updateParagraphe(MyyAxis);
              offset--;
            }
            //console.log("ADDED update paragraphe SET yAxis = yAxis + " + offset + " where yAxis > " + start + "  AND id_text = 1");
          }
        }
      }
      lastyAxis = $(this).attr("data-yAxis");
      $(this).attr("data-yAxis", paragraphe);
    });
    if (offset === 0 && offsetAdd !== 0) {
      //new paragraphe at the end
      while (offsetAdd >= 0) {
        MyyAxis = toAdd + offsetAdd;
        updateParagraphe(MyyAxis);
        offsetAdd--;
      }
    }

    if (offset === 0) {
      return false;
    } else {
      return true;
    }
  }
  $('textarea').each(function () {resize(this);}).on('input', function () {resize(this);});
  function resize(e) {
    $(e).css({'height':'auto','overflow-y':'hidden'}).height('calc( '+e.scrollHeight+'px - 1rem )');
  }

});

function OnPaste_StripFormatting(elem, e) {

  if (e.originalEvent && e.originalEvent.clipboardData && e.originalEvent.clipboardData.getData) {
    e.preventDefault();
    var text = e.originalEvent.originalEvent.clipboardData.getData('text/plain');
    text = text.replace(/(\n\n)/gm, "\n");
    window.document.execCommand('insertText', false, text);
  } else if (e.clipboardData && e.clipboardData.getData) {
    e.preventDefault();
    var text = e.clipboardData.getData('text/plain');
    text = text.replace(/(\n\n)/gm, "\n");
    window.document.execCommand('insertText', false, text);
  } else if (window.clipboardData && window.clipboardData.getData) {
    // Stop stack overflow
    if (!_onPaste_StripFormatting_IEPaste) {
      _onPaste_StripFormatting_IEPaste = true;
      e.preventDefault();
      window.document.execCommand('ms-pasteTextOnly', false);
    }
    _onPaste_StripFormatting_IEPaste = false;
  }

}
if (typeof String.prototype.startsWith != 'function') {
  // see below for better implementation!
  String.prototype.startsWith = function (str){
    return this.indexOf(str) === 0;
  };
}
