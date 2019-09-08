$(function() {
  var hostname = $(location).attr('hostname');
  var channel = $(location).attr('hash');

  // console.log("host: " + hostname + " channel: " + channel);

  // fuck parsing the hostname
  var servers = {
    "f.perlbot.pl":        "localhost:perlbot:",
    "freenode.perlbot.pl": "localhost:perlbot:",
    "m.perlbot.pl":        "localhost:perlbot-magnet:",
    "magnet.perlbot.pl":   "localhost:perlbot-magnet:",
    "o.perlbot.pl":   "localhost:perlbot-oftc:",
    "oftc.perlbot.pl":   "localhost:perlbot-oftc:",
    "f.perl.bot":        "localhost:perlbot:",
    "freenode.perl.bot": "localhost:perlbot:",
    "m.perl.bot":        "localhost:perlbot-magnet:",
    "magnet.perl.bot":   "localhost:perlbot-magnet:",
    "o.perl.bot":   "localhost:perlbot-oftc:",
    "oftc.perl.bot":   "localhost:perlbot-oftc:",
  };

  if (channel && servers[hostname]) { // only do this if we have a channel and a valid server
    // console.log("found default channel to post: "+servers[hostname]+channel);
    var option = $("option[value='"+servers[hostname]+channel+"']");
    // console.log(option);
    option.prop('selected', true);
  }
  
  if (servers[hostname]) {
    var badoptions = $("select#channel option:not([value^='"+servers[hostname]+"'])");
    console.log(badoptions);
    badoptions.remove();
  }
});

$(function() {
  var showingmodules = 0;
  var showingeval = 0;

   var editor;

    var use_editor = function() {
      if ($("#raw_editor").is(":checked")) {
        if (editor) {
          $("#paste").val(editor.getValue());
        }
	$("#editor").hide();
	$("#paste").show();
      } else {
	$("#paste").hide();
	$("#editor").show();
        if (!editor) {
	  $("#editor").text($("#paste").val());
        } else {
          editor.setValue($("#paste").val(),0);
          editor.clearSelection();
        }
      }
    };
 
    use_editor();
    $("#raw_editor").on("change", use_editor);
    editor = ace.edit("editor");
    //editor.setTheme("ace/theme/twilight");

    //safely delete all bindings
    var save_keys={};
    Object.keys(editor.keyBinding.$defaultHandler.commandKeyBinding)
        .filter((value) => value.match(/(?:(?:backspac|hom)e|d(?:elete|own)|(?:righ|lef)t|end|up|tab)/))
        .forEach((key) => save_keys[key] = editor.keyBinding.$defaultHandler.commandKeyBinding[key]); 

    editor.keyBinding.$defaultHandler.commandKeyBinding = save_keys;


    $("#language").on('change', function () {
      var language = $('#language option').filter(':selected').attr('data-lang');
      console.log("language: ", language);
      editor.session.setMode("ace/mode/" + language);
    });
    
    var channel = $(location).attr('hash');
    if (channel == "#perl6") {
     $("#language").val("perl6").change();
    } else if (channel == "#cobol") {
     $("#language").val("cobol").change();
    }

    editor.session.setMode("ace/mode/perl");

//    editor.setOptions({fontFamily: ['AnonymousPro', 'monospace', 'mono']});


    function setup_columns() {
      if (showingeval && showingmodules) {
        $("#editors").removeClass().addClass('col-md-6');
        $("#evalcol").removeClass().addClass('col-md-4');
        $("#modules").removeClass().addClass('col-md-2');
      } else if (showingeval) {
        $("#editors").removeClass().addClass('col-md-10');
        $("#evalcol").removeClass().addClass('col-md-2');
        $("#modules").removeClass().addClass('hidden');
      } else if (showingmodules) {
        $("#editors").removeClass().addClass('col-md-10');
        $("#evalcol").removeClass().addClass('hidden');
        $("#modules").removeClass().addClass('col-md-2');
      } else {
        $("#editors").removeClass().addClass('col-md-12');
        $("#evalcol").removeClass().addClass('hidden');
        $("#modules").removeClass().addClass('hidden');
      }
    };

    function resizeAce() {
      var h = window.innerHeight;
      if (h > 360) {
        $('#editor').css('height', (h - 175).toString() + 'px');
      }
    };
    $(window).on('resize', function () {
      resizeAce();
    });
    resizeAce();

    $("#submit").on('click', function () {
      var code = $("#raw_editor").is(":checked") ?
                 $("#paste").val() :
                 editor.getValue();
      $("#paste").text(code); // copy to the textarea
    });

    $('#evalme').on('click', function () {
      showingeval = 1;
      $('#eval').text("Evaluating...");
      
      setup_columns();

      var code = $("#raw_editor").is(":checked") ?
                 $("#paste").val() :
                 editor.getValue();

      var language = $('#language option').filter(':selected').val();

      $.ajax('/eval', {
        method: 'post',
        data: {code: code, language: language},
        dataType: "json",
        success: function(data, status) {
	  console.log("data out", data);
	  var keys = Object.keys(data.evalout);
	  var outputarr = [];

          if (keys.length > 1) {
            outputarr = $.map(data.evalout, function(output, lang) {
             return "[[ "+lang+" ]]\n"+output+"\n\n";
	    });
          } else {
            outputarr = [data.evalout[keys[0]]];
          }
          console.log("outputarr", outputarr);
	  console.log(outputarr.join("\n"));

	  $('#eval').text(outputarr.join("\n"));
        }
      });
    });

  $("#showmodules").on('click', function() {
    showingmodules = 1 - showingmodules;

    setup_columns();
  });

});
