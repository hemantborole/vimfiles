/**
 * Plugin to interact with firebug.
 *
 * Usage:
 *   :firebug                     opens firebug
 *   :firebug open                opens firebug
 *   :firebug close               closes firebug
 *   :firebug toggle              if closed, open firebug, otherwise close it.
 *   :firebug console-focus       places the cursor in the console command line.
 *   :firebug console-clear       clears the console
 *   :firebug tab <tabname>       focuses the specified firebug tab (console,
 *                                html, css, etc)
 *   :[count]firebug tabnext      focuses the next firebug tab (wraps at the end).
 *   :[count]firebug tabprevious  focuses the prev firebug tab (wraps at the
 *                                begining).
 *
 * The following vimpartor key bindings are supported while the firebug panel
 * has focus, meaning that they will perform the expected action on the firebug
 * panel instead of the current web page.
 *   - scrolling:         j, k, gg, G
 *   - tab switching:     gt, gT, g0, g$
 *
 * Note: the wincmd plugin[1] supports navigating to/from firebug panels like
 * regular html frames, giving them focus for allowing you to then navigate via
 * the supported vimperator key bindings noted above.
 *
 * [1] http://vimperator.org/trac/ticket/56
 *
 * @author Eric Van Dewoetine (ervandew@gmail.com)
 * @version 0.2
 *
 * TODO:
 *   - add horizontal scrolling: h,l,0,$
 *   - add <c-d>, <c-u>, <c-b>, <c-f> scrolling support
 *     - buffer.js:buffer.scrollByScrollSize
 *     - buffer.js:buffer.scrollPages
 *   - modify scrolling in panels to scroll down by focussing entries in the
 *     page.
 *   - for expandable/collapsable elements, add zo, zc to treat them like folds
 */

function FirebugVimperator(){
  var fbContentBox = document.getElementById('fbContentBox');
  var panelFocused = null;

  // event listener to keep track of if/which firebug panel is focused.
  window.addEventListener('focus', function(event){
    var doc = null;
    if (event.target.nodeType == Node.DOCUMENT_NODE){
      doc = event.target;
    }else if (event.target.ownerPanel){
      doc = event.target.ownerPanel.document;
    }else if (event.target.parentNode.ownerPanel){ // script panel
      doc = event.target.parentNode.ownerPanel.document;
    }

    if (doc.location == 'chrome://firebug/content/panel.html'){
      for each (node in doc.getElementsByClassName('panelNode')){
        var match = /.*\spanelNode-(\w+)\s.*/.exec(node.className);
        if (match && node.getAttribute('active') == 'true'){
          panelFocused = match[1];
          return;
        }
      }
    }

    panelFocused = null;
  }, true);

  // listen for user clicking a firebug tab, to set proper focus
  document.getElementById('fbPanelBar1').addEventListener(
    'click', function(event){
      var name = event.target.getAttribute('label').toLowerCase();
      if (name == 'css'){
        name = 'stylesheet';
      }
      panelFocused = name;
    },
    true
  );
  document.getElementById('fbPanelBar2').addEventListener(
    'click', function(event){
      var name = event.target.getAttribute('label').toLowerCase();
      if (name == 'style'){
        name = 'css';
      }else if (name == 'dom'){
        name = 'domSide';
      }
      panelFocused = name;
    },
    true
  );

  // hook into buffer scrolling to support scrolling in firebug panels
  var bufferScrollLines = buffer.scrollLines;
  buffer.scrollLines = function(lines){
    if (panelFocused){
      var node = FirebugContext.getPanel(panelFocused, true).panelNode;
      if (panelFocused == 'script'){
        node = node.lastChild;
      }
      node.scrollTop += 10 * lines;
    }else{
      bufferScrollLines(lines);
    }
  };

  var bufferScrollToPercentile = buffer.scrollToPercentile;
  buffer.scrollToPercentile = function(percentage){
    if (panelFocused){
      var node = FirebugContext.getPanel(panelFocused, true).panelNode;
      if (panelFocused == 'script'){
        node = node.lastChild;
      }
      node.scrollTop = node.scrollHeight * (percentage / 100);
    }else{
      bufferScrollToPercentile(percentage);
    }
  };

  // hook into tab switching
  var tabsSelect = tabs.select;
  tabs.select = function(spec, wrap){
    if (panelFocused){
      if (spec !== undefined && spec !== ""){
        var names = fbv._getPanelNames();
        var browser = FirebugChrome.getCurrentBrowser();
        var position = names.indexOf(panelFocused);
        var focus = fbv._focusPanel;
        if (position == -1){
          names = fbv._getSidePanelNames(browser.chrome.getSelectedPanel());
          position = names.indexOf(panelFocused);
          focus = fbv._focusSidePanel;
        }
        var last = names.length - 1;
        var length = names.length;

        if (typeof spec === "number")
          position = spec;
        else if (spec === "$")
          position = last;
        else if (/^[+-]\d+$/.test(spec))
          position += parseInt(spec, 10);
        else if (/^\d+$/.test(spec))
          position = parseInt(spec, 10);

        if (position > last)
          position = wrap ? position % length : last;
        else if (position < 0)
          position = wrap ? (position % length) + length : 0;
        focus(names[position]);
      }
    }else{
      tabsSelect(spec, wrap);
    }
  };

  return {
    open: function(){
      if (fbContentBox.collapsed)
        Firebug.toggleBar(true, 'console');

      // when :firebug (open|toggle) mapped via key binding
      // (map ... :firebug toggle<cr>), focus needs to be delayed.
      setTimeout(function(){
        var browser = FirebugChrome.getCurrentBrowser();
        browser.chrome.getSelectedPanel().document.defaultView.focus();
      }, 100);
    },

    close: function(){
      if (!fbContentBox.collapsed)
        Firebug.toggleBar();
    },

    toggle: function(){
      if (fbContentBox.collapsed)
        fbv.open();
      else
        fbv.close();
    },

    console_focus: function(){
      Firebug.CommandLine.focus(FirebugContext);
    },

    console_clear: function(){
      Firebug.Console.clear();
    },

    tab: function(args){
      fbv.open();
      var name = args.arguments[0].toLowerCase();
      if (name == 'css'){
        name = 'stylesheet';
      }
      fbv._focusPanel(name);
    },

    tabnext: function(args, count){
      fbv._gotoNextPrevTabName(count, false);
    },

    tabprevious: function(args, count){
      fbv._gotoNextPrevTabName(count, true);
    },

    _execute: function(args, count){
      var name = args.arguments.length ?
        args.arguments.shift().replace('-', '_') : 'open';
      var cmd = fbv[name];
      if (!cmd){
        liberator.echoerr('Unsupported firebug command: ' + name);
        return false;
      }
      count = count > 1 ? count : 1;
      return cmd(args, count);
    },

    _gotoNextPrevTabName: function(count, previous){
      var names = fbv._getPanelNames();
      var browser = FirebugChrome.getCurrentBrowser();
      var index = names.indexOf(browser.chrome.getSelectedPanel().name);
      count = count % names.length;
      if(previous){
        index = index - count;
        if (index < 0){
          index += names.length;
        }
      }else{
        index = index + count;
        if (index >= names.length){
          index -= names.length;
        }
      }
      fbv.tab({arguments: [names[index]]});
    },

    _getPanelNames: function(){
      var panels = Firebug.getMainPanelTypes(FirebugContext);
      return [p.prototype.name for each (p in panels)];
    },

    _getSidePanelNames: function(mainPanel){
      var panels = Firebug.getSidePanelTypes(FirebugContext, mainPanel);
      return [p.prototype.name for each (p in panels)];
    },

    _focusPanel: function(name){
      var browser = FirebugChrome.getCurrentBrowser();
      browser.chrome.selectPanel(name);
      browser.chrome.syncPanel();
      Firebug.showBar(true);
      var panel = FirebugContext.getPanel(name, true);
      if (name == 'script'){
        panel.panelNode.lastChild.focus();
      }else{
        panel.panelNode.focus();
      }
      panelFocused = name;
    },

    _focusSidePanel: function(name){
      var browser = FirebugChrome.getCurrentBrowser();
      browser.chrome.selectSidePanel(name);
      browser.chrome.syncPanel();
      Firebug.showBar(true);
      browser.chrome.getSelectedSidePanel().document.defaultView.focus();
      panelFocused = name;
    },

    _completer: function(context){
      var commands = [];
      for (var name in fbv){
        if (name.indexOf('_') !== 0 && fbv.hasOwnProperty(name)){
          commands.push(name.replace('_', '-'));
        }
      }
      commands = [[c, ''] for each (c in commands)];
      return [0, completion.filter(commands, context.filter)];
    }
  };
}

var fbv = new FirebugVimperator();

commands.add(['firebug'],
  'Control firebug from within vimperator.',
  function(args, special, count, modifiers) { fbv._execute(args, count); },
  { count: true, argCount: '*', completer: fbv._completer }
);
