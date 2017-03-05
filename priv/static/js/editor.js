$(function() {
  var console_channel;

  var setup_console = function(version){
    var header = 'Interactive Elixir (' + version + ')\n';
    window.jqconsole = $('#console').jqconsole(header, 'iex(1)> ', '...(1)>');

    // register error styles?
    jqconsole.RegisterMatching('**','/0','error');

    // Move to line start Ctrl+A.
    jqconsole.RegisterShortcut('A', function() {
      jqconsole.MoveToStart();
      handler();
    });
    // Move to line end Ctrl+E.
    jqconsole.RegisterShortcut('E', function() {
      jqconsole.MoveToEnd();
      handler();
    });
    // Clear prompt
    jqconsole.RegisterShortcut('R', function() {
      jqconsole.AbortPrompt();
      handler();
    });
  };


  var BLOCK_OPENERS, multiLineHandler,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  BLOCK_OPENERS = ["do"];
  var TOKENS;

  TOKENS = /\s+|\d+(?:\.\d*)?|"(?:[^"]|\\.)*"|'(?:[^']|\\.)*'|\/(?:[^\/]|\\.)*\/|[-+\/*]|[<>=]=?|:?[a-z@$][\w?!]*|[{}()\[\]]|[^\w\s]+/ig;


  var multiLineHandler = function(command) {
    var braces, brackets, last_line_changes, levels, line, parens, token, _i, _j, _len, _len1, _ref, _ref1;
    levels = 0;
    last_line_changes = 0;
    _ref = command.split('\n');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      last_line_changes = 0;
      _ref1 = line.match(TOKENS) || [];

      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        token = _ref1[_j];
        if (__indexOf.call(BLOCK_OPENERS, token) >= 0) {
          levels++;
          last_line_changes++;
        } else if (token === 'end') {
          levels--;
          last_line_changes--;
        }
        if (levels < 0) {
          return false;
        }
      }
    }

    if (levels > 0) {
      if (last_line_changes > 0) {
        return 1;
      } else if (last_line_changes < 0) {
        return -1;
      } else {
        return 0;
      }
    } else {
      return false;
    }
  };

  var handler = function(command) {
    if(command){
      console_channel.push("shell:stdin", {data: command});
    }
    return jqconsole.Prompt(true, handler, multiLineHandler);
  };

  var joinHandler = function(message) {
    console_channel = channel;
    $status.text(message.status);
    setup_console(message.version);
    handler();
  }

  var _phoenix = require("phoenix");
  var socket = new _phoenix.Socket("/shell", { params: { token: window.userToken } });
  socket.connect();
  var $status = $('#status');
  var channel = socket.channel("shell", {});

  channel.onError( () => console.log("The channel reported an error") )
  channel.onClose( () => console.log("The channel has closed gracefully") )
  channel.join()
    .receive("ok", joinHandler)
    .receive("error", resp => { console.log("Error: ", resp) } )

  channel.on("stdout", function(message){
    var txt = JSON.parse(message["data"]);

    if(txt){
      prompt = $('.jqconsole-cursor').parent().find('span')[0];
      $(prompt).html(txt.prompt);
      jqconsole.SetPromptLabel(txt.prompt);
      jqconsole.prompt_label_continue = txt.prompt.replace("iex", "...");

      jqconsole.Write(txt.result + '\n', txt.type);
      jqconsole.Write(':' + txt.type + '\n');
    }
  });
});
