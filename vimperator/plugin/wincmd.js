/**
 * Plugin to facilitate frame navigation by mimicking vim's
 * <c-w>/:wincmd functionality.
 *
 * Usage:
 *   [count]<c-w>j
 *   [count]<c-w><c-j>
 *      Moves focus one or more frames below the current frame.
 *
 *   [count]<c-w>k
 *   [count]<c-w><c-k>
 *      Moves focus one or more frames above the current frame.
 *
 *   [count]<c-w>l
 *   [count]<c-w><c-l>
 *      Moves focus one or more frames to the left of the current frame.
 *
 *   [count]<c-w>h
 *   [count]<c-w><c-h>
 *      Moves focus one or more frames to the right of the current frame.
 *
 *   [count]<c-w>w
 *   [count]<c-w><c-w>
 *
 *   The above commands can also be executed with ":wincmd":
 *
 *   :[count]wincm[d] {arg}
 *       Equivalent to executing [count]<c-w>{arg}
 *
 *   Note: none of the above will wrap around should you reach the edge of
 *   which ever direction you are moving, with the exception of <c-w> which
 *   will cycle through all frames, wrapping back to beginning after reaching
 *   the last frame..
 *
 * TODO
 *   - attempt to take cursor (caret) location into account.
 *   - frame filtering (ads, etc.)
 *   - shortcut to focus largest frame
 *   - integrate with the "SplitBrowser" addon and "splitBrowser.js" plugin.
 *   - if possible, add other wincmd equivalent commands
 *     (J, K, L, H, X, T, etc.)
 *
 * @author Eric Van Dewoetine
 * @version 0.1
 */

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
    return true;
  }, {count: true, argCount: 1}
);

mappings.add([modes.NORMAL], ["<c-w>w", "<c-w><c-w>"],
    "Cycle through frames",
    function (count) {
      wincmd.setFrameFocus(count, function(count, current, frames){
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
      wincmd.setFrameFocus(count, function(count, current, frames){
        return wincmd.nextVertical(count, current, frames, true);
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>k", "<c-w><c-k>"],
    "Move to the frame above the current one.",
    function (count) {
      wincmd.setFrameFocus(count, function(count, current, frames){
        return wincmd.nextVertical(count, current, frames, false);
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>l", "<c-w><c-l>"],
    "Move to the frame to the right of the current one.",
    function (count) {
      wincmd.setFrameFocus(count, function(count, current, frames){
        return wincmd.nextHorizontal(count, current, frames, true);
      });
    },
    { flags: Mappings.flags.COUNT }
);

mappings.add([modes.NORMAL], ["<c-w>h", "<c-w><c-h>"],
    "Move to the frame to the left of the current one.",
    function (count) {
      wincmd.setFrameFocus(count, function(count, current, frames){
        return wincmd.nextHorizontal(count, current, frames, false);
      });
    },
    { flags: Mappings.flags.COUNT }
);

const wincmd = {
  dimensions: function(frame){
    var frameElement = frame.frameElement;
    var offsetTop = frameElement.offsetTop;
    var offsetLeft = frameElement.offsetLeft;
    var parent = frame.parent;
    if (parent != frame && parent.frameElement){
      do {
        offsetTop += parent.frameElement.offsetTop;
        offsetLeft += parent.frameElement.offsetLeft;
      } while((parent = parent.parent) && parent != frame && parent.frameElement)
    }
    return {
      top: offsetTop,
      bottom: offsetTop + frameElement.offsetHeight,
      left: offsetLeft,
      right: offsetLeft + frameElement.offsetWidth
    };
  },

  nextVertical: function(count, current, frames, down){
    current = current > 0 ? current : 0;
    var index = current;
    for (var ii = 0; ii < count; ii++){
      var cdimen = frames[index].dimensions;
      var ndimen = undefined;
      for (var jj = 0; jj < frames.length; jj++){
        frame = frames[jj];
        var fdimen = frame.dimensions;
        if ((
            (down && fdimen.top >= cdimen.bottom) ||
            (!down && fdimen.bottom <= cdimen.top)
        ) && (
            (fdimen.left > cdimen.left && fdimen.left < cdimen.right) ||
            (fdimen.right > cdimen.left && fdimen.right < cdimen.right) ||
            (fdimen.left <= cdimen.left && fdimen.right >= cdimen.right)
        ))
        {
          if(!ndimen || (
              (down && fdimen.top < ndimen.top) ||
              (!down && fdimen.bottom > ndimen.bottom))
          ){
            ndimen = fdimen;
            index = jj;
          }
        }
      }
    }
    return index;
  },

  nextHorizontal: function(count, current, frames, right){
    current = current > 0 ? current : 0;
    var index = current;
    for (var ii = 0; ii < count; ii++){
      var cdimen = frames[index].dimensions;
      var ndimen = undefined;
      for (var jj = 0; jj < frames.length; jj++){
        frame = frames[jj];
        var fdimen = frame.dimensions;
        if ((
            (right && fdimen.left >= cdimen.right) ||
            (!right && fdimen.right <= cdimen.left)
        ) && (
            (fdimen.top > cdimen.top && fdimen.top < cdimen.bottom) ||
            (fdimen.bottom > cdimen.top && fdimen.bottom < cdimen.bottom) ||
            (fdimen.top <= cdimen.top && fdimen.bottom >= cdimen.bottom)
        ))
        {
          if(!ndimen || (
              (right && fdimen.left < ndimen.left) ||
              (!right && fdimen.right > ndimen.right))
          ){
            ndimen = fdimen;
            index = jj;
          }
        }
      }
    }
    return index;
  },

  // Mostly copied from buffer.shiftFrameFocus
  setFrameFocus: function(count, frameChooser){
    if (!window.content.document instanceof HTMLDocument)
      return;

    var frames = [];

    // find all frames - depth-first search
    (function (frame) {
        if (frame.document.body.localName.toLowerCase() == "body")
          frames.push(frame);
        Array.forEach(frame.frames, arguments.callee);
    })(window.content);

    // remove all unfocusable frames
    var start = document.commandDispatcher.focusedWindow;
    frames = frames.filter(function (frame) {
      frame.focus();
      if (frame.frameElement &&
        document.commandDispatcher.focusedWindow == frame)
      {
        frame.dimensions = wincmd.dimensions(frame);
        return true;
      }
      return false;
    });
    start.focus();

    var doc = window.content.document;
    if (frames.length > 0){
      // find the currently focused frame index
      var current = frames.indexOf(document.commandDispatcher.focusedWindow);

      var index = frameChooser(count > 1 ? count : 1, current, frames);

      // focus next frame and scroll into view
      frames[index].focus();
      if (frames[index] != window.content)
        frames[index].frameElement.scrollIntoView(false);

      doc = frames[index].document;
    }
    var indicator = util.xmlToDom(<div id="liberator-frame-indicator"/>, doc);
    doc.body.appendChild(indicator);

    // remove the frame indicator
    setTimeout(function(){ doc.body.removeChild(indicator); }, 500);
  }
};
