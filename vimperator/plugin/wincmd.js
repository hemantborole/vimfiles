/**
 * Plugin to facilitate frame navigation by mimicking vim's
 * <c-w>/:wincmd functionality.
 *
 * TODO
 *   - improve adjacent frame detection
 *   - attempt to take cursor (caret) location into account.
 *   - frame filtering (ads, etc.)
 *   - shortcut to focus largest frame
 *
 * @author Eric Van Dewoetine
 * @version 0.1
 */

// FIXME: in command mode setFrameFocus doesn't have access to the currently
// focused frame, so all :wincmd commands start at frames[0].
commands.add(["wincm[d]"],
  "Change focus to a different frame",
  function(args, special, count, modifiers) {
    count = count > 1 ? count : "";
    switch(args.string){
      case "j":
        events.feedkeys(count + '<c-w>j');
        break;
      case "k":
        events.feedkeys(count + '<c-w>k');
        break;
      case "h":
        events.feedkeys(count + '<c-w>h');
        break;
      case "l":
        events.feedkeys(count + '<c-w>l');
        break;
      case "w":
        events.feedkeys(count + '<c-w>w');
        break;
      default:
        liberator.echoerr("unsupported argument for wincmd");
        return false;
    }
  }, {count: true, argCount: 1}
);

mappings.add([modes.NORMAL], ["<c-w>w", "<c-w><c-w>"],
    "Cycle through frames",
    function (count) {
      setFrameFocus(count, function(count, current, frames){
        if (current < frames.length - count){
          index = current + count;
        }else{
          index = current + count - frames.length;
        }
        return index < frames.length ? index : frames.length - 1;
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>j", "<c-w><c-j>"],
    "Move to the frame below the current one.",
    function (count) {
      setFrameFocus(count, function(count, current, frames){
        current = current > 0 ? current : 0;
        var below = [];
        var ctop = frames[current].frameElement.offsetTop;
        for (var ii = 0; ii < frames.length; ii++){
          frame = frames[ii];
          if (frame.frameElement.offsetTop > ctop){
            below.push({frame: frame, index: ii});
          }
        }
        if (below.length){
          below.sort(function(f1, f2){
            return f1.frame.frameElement.offsetTop - f2.frame.frameElement.offsetTop;
          });
          return count <= below.length ? below[count - 1].index : below[below.length - 1].index;
        }
        return current;
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>k", "<c-w><c-k>"],
    "Move to the frame above the current one.",
    function (count) {
      setFrameFocus(count, function(count, current, frames){
        current = current > 0 ? current : 0;
        var above = [];
        var ctop = frames[current].frameElement.offsetTop;
        var cleft = frames[current].frameElement.offsetLeft;
        for (var ii = 0; ii < frames.length; ii++){
          frame = frames[ii];
          if (frame.frameElement.offsetLeft == cleft && frame.frameElement.offsetTop < ctop){
            above.push({frame: frame, index: ii});
          }
        }
        if (above.length){
          above.sort(function(f1, f2){
            return f2.frame.frameElement.offsetTop - f1.frame.frameElement.offsetTop;
          });
          return count <= above.length ? above[count - 1].index : above[above.length - 1].index;
        }
        return current;
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>l", "<c-w><c-l>"],
    "Move to the frame to the right of the current one.",
    function (count) {
      setFrameFocus(count, function(count, current, frames){
        current = current > 0 ? current : 0;
        var right = [];
        var cleft = frames[current].frameElement.offsetLeft;
        for (var ii = 0; ii < frames.length; ii++){
          frame = frames[ii];
          if (frame.frameElement.offsetLeft > cleft){
            right.push({frame: frame, index: ii});
          }
        }
        if (right.length){
          right.sort(function(f1, f2){
            return f1.frame.frameElement.offsetLeft - f2.frame.frameElement.offsetLeft;
          });
          var index = count <= right.length ? right[count - 1].index : right[right.length - 1].index;
          return index;
        }
        return current;
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>h", "<c-w><c-h>"],
    "Move to the frame to the left of the current one.",
    function (count) {
      setFrameFocus(count, function(count, current, frames){
        current = current > 0 ? current : 0;
        var left = [];
        var cleft = frames[current].frameElement.offsetLeft;
        for (var ii = 0; ii < frames.length; ii++){
          frame = frames[ii];
          if (frame.frameElement.offsetLeft < cleft){
            left.push({frame: frame, index: ii});
          }
        }
        if (left.length){
          left.sort(function(f1, f2){
            var cmp = f2.frame.frameElement.offsetLeft - f1.frame.frameElement.offsetLeft;
            if (cmp == 0){
              return f2.frame.frameElement.offsetTop - f1.frame.frameElement.offsetTop;
            }
            return cmp
          });
          return count <= left.length ? left[count - 1].index : left[left.length - 1].index;
        }
        return current;
      });
    },
    { flags: Mappings.flags.COUNT }
);

// Mostly copied from buffer.shiftFrameFocus
function setFrameFocus(count, frameChooser){
  if (!window.content.document instanceof HTMLDocument)
    return;

  var frames = [];

  // find all frames - depth-first search
  (function (frame) {
      if (frame.document.body.localName.toLowerCase() == "body")
        frames.push(frame);
      Array.forEach(frame.frames, arguments.callee);
  })(window.content);

  if (frames.length == 0) // currently top is always included
      return;

  // remove all unfocusable frames
  var start = document.commandDispatcher.focusedWindow;
  frames = frames.filter(function (frame) {
    frame.focus();
    return frame.frameElement && document.commandDispatcher.focusedWindow == frame;
  });
  start.focus();

  // find the currently focused frame index
  var current = frames.indexOf(document.commandDispatcher.focusedWindow);

  var index = frameChooser(count > 1 ? count : 1, current, frames);

  // focus next frame and scroll into view
  frames[index].focus();
  if (frames[index] != window.content)
    frames[index].frameElement.scrollIntoView(false);

  // add the frame indicator
  var doc = frames[index].document;
  var indicator = util.xmlToDom(<div id="liberator-frame-indicator"/>, doc);
  doc.body.appendChild(indicator);

  // remove the frame indicator
  setTimeout(function () { doc.body.removeChild(indicator); }, 500);
}
