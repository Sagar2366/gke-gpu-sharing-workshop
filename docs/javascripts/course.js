/* course.js: interactive pieces for the workshop site.
 *
 *  Codelab view (pages containing <div class="codelab-marker">):
 *    - one step (H2 section) at a time, left step list, Back / Next buttons,
 *      "N mins remaining" from each H2's data-mins, URL hash #0, #1, ... like Google Codelabs
 *  Tasks: every `!!! step` admonition gets "Task N of M", a "Mark as done" button and a small
 *    progress bar per codelab step (saved in the browser). A step is ticked in the left list
 *    when all its core tasks are done.
 *  Flip cards, quizzes, hotspots: see the markup notes at the bottom.
 *
 * Works with Material's instant navigation (document$) and plain page loads.
 */
(function () {
  "use strict";

  function key(k) { return "gpuws:" + location.pathname.replace(/index\.html$/, "") + ":" + k; }
  function load(k) { try { return localStorage.getItem(key(k)); } catch (e) { return null; } }
  function save(k, v) { try { v === null ? localStorage.removeItem(key(k)) : localStorage.setItem(key(k), v); } catch (e) { /* private mode */ } }


  /* ------------------------------------------------------------------ mermaid */
  // Diagrams are <div class="mermaid-src">source</div>. We render them only once they're
  // visible: Mermaid can't measure text inside display:none (hidden codelab steps, tabs).
  var MERMAID_LOCAL = (function () {
    var s = document.querySelector('script[src*="javascripts/course.js"]');
    return s ? s.src.replace(/course\.js(\?.*)?$/, "vendor/mermaid.min.js") : "javascripts/vendor/mermaid.min.js";
  })();
  var MERMAID_CDN = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js";
  var mermaidReady = null, mermaidSeq = 0;

  function loadScript(src) {
    return new Promise(function (res, rej) {
      var el = document.createElement("script");
      el.src = src; el.onload = res; el.onerror = rej;
      document.head.appendChild(el);
    });
  }
  function getMermaid() {
    if (!mermaidReady) {
      mermaidReady = (window.mermaid ? Promise.resolve() : loadScript(MERMAID_LOCAL).catch(function () { return loadScript(MERMAID_CDN); }))
        .then(function () {
          var dark = document.body.getAttribute("data-md-color-scheme") === "slate";
          window.mermaid.initialize({ startOnLoad: false, securityLevel: "loose", theme: dark ? "dark" : "default",
            fontFamily: "Inter, Roboto, Arial, sans-serif", flowchart: { htmlLabels: true, useMaxWidth: true } });
          return window.mermaid;
        });
    }
    return mermaidReady;
  }
  function renderDiagrams(scope) {
    var pending = Array.prototype.slice.call((scope || document).querySelectorAll(".mermaid-src:not([data-rendered])"))
      .filter(function (el) { return el.offsetParent !== null || el.getClientRects().length; });
    if (!pending.length) return;
    getMermaid().then(function (mermaid) {
      pending.forEach(function (el) {
        if (el.dataset.rendered) return;
        el.dataset.rendered = "1";
        var src = el.textContent;
        var id = "mmd-" + (++mermaidSeq);
        mermaid.render(id, src).then(function (out) {
          var box = document.createElement("div");
          box.className = "mermaid-out";
          box.innerHTML = out.svg;
          el.style.display = "none";
          el.parentNode.insertBefore(box, el.nextSibling);
        }).catch(function (err) {
          el.classList.add("mermaid-error");
          el.setAttribute("title", "Diagram error: " + (err && err.message ? err.message : err));
          var stray = document.getElementById("d" + id); if (stray) stray.remove();
        });
      });
    }).catch(function () {
      pending.forEach(function (el) { el.classList.add("mermaid-offline"); });
    });
  }
  // re-check when tabs switch or <details> open
  document.addEventListener("change", function (e) { if (e.target && e.target.matches && e.target.matches(".tabbed-set > input")) setTimeout(renderDiagrams, 30); });
  document.addEventListener("toggle", function () { setTimeout(renderDiagrams, 30); }, true);

  /* ------------------------------------------------------------------ codelab */
  var CL = null; // {sections, nav items, go(), refreshNav()}

  function initCodelab(article) {
    var marker = article.querySelector(".codelab-marker");
    if (!marker || article.dataset.codelabReady) return null;
    article.dataset.codelabReady = "1";
    document.body.classList.add("codelab-mode");

    var title = (article.querySelector("h1") || {}).textContent || document.title;
    var catalog = marker.dataset.catalog || "../index.html";

    // Group children into sections, one per H2. Anything before the first H2 joins section 0.
    var children = Array.prototype.slice.call(article.children);
    var sections = [], pre = [], cur = null;
    children.forEach(function (el) {
      if (el === marker) return;
      if (el.tagName === "H2") {
        cur = document.createElement("section");
        cur.className = "cl-step";
        cur.dataset.mins = el.dataset.mins || "0";
        sections.push(cur);
        if (sections.length === 1) pre.forEach(function (p) { cur.appendChild(p); });
        cur.appendChild(el);
      } else if (cur) {
        cur.appendChild(el);
      } else {
        pre.push(el);
      }
    });
    if (!sections.length) return null;

    // Shell
    var top = document.createElement("div");
    top.className = "cl-topbar";
    top.innerHTML = '<a class="cl-home" title="All codelabs">&#8592;</a><span class="cl-title"></span>' +
      '<span class="cl-remaining"><span class="cl-clock">&#9719;</span> <span class="cl-mins"></span></span>';
    top.querySelector(".cl-title").textContent = title.replace(/\s*¶\s*$/, "");
    top.querySelector(".cl-home").href = catalog;

    var shell = document.createElement("div"); shell.className = "cl-shell";
    var nav = document.createElement("nav"); nav.className = "cl-nav"; nav.setAttribute("aria-label", "Codelab steps");
    var main = document.createElement("div"); main.className = "cl-main";
    var controls = document.createElement("div"); controls.className = "cl-controls";
    controls.innerHTML = '<button type="button" class="cl-back">Back</button><button type="button" class="cl-next">Next</button>';

    var items = sections.map(function (s, i) {
      var h2 = s.querySelector("h2");
      var text = h2.textContent.replace(/\s*¶\s*$/, "").replace(/^\s*\d+\.\s*/, "");
      var a = document.createElement("a");
      a.className = "cl-nav-item";
      a.href = "#" + i;
      a.innerHTML = '<span class="cl-num"></span><span class="cl-label"></span>';
      a.querySelector(".cl-num").textContent = i + 1;
      a.querySelector(".cl-label").textContent = text;
      nav.appendChild(a);
      main.appendChild(s);
      return a;
    });
    main.appendChild(controls);
    shell.appendChild(nav); shell.appendChild(main);
    article.appendChild(top); article.appendChild(shell);

    var current = 0;
    function go(i, opts) {
      i = Math.max(0, Math.min(sections.length - 1, i));
      current = i;
      sections.forEach(function (s, j) { s.classList.toggle("active", j === i); });
      items.forEach(function (a, j) { a.classList.toggle("active", j === i); a.classList.toggle("visited", j < i); });
      var mins = sections.slice(i).reduce(function (t, s) { return t + (parseInt(s.dataset.mins, 10) || 0); }, 0);
      top.querySelector(".cl-mins").textContent = mins + " mins remaining";
      var back = controls.querySelector(".cl-back"), next = controls.querySelector(".cl-next");
      back.style.visibility = i === 0 ? "hidden" : "visible";
      next.textContent = i === sections.length - 1 ? "Done" : "Next";
      if (!opts || !opts.keepHash) history.replaceState(null, "", "#" + i);
      save("codelab-step", String(i));
      setTimeout(function () { renderDiagrams(sections[i]); }, 0);
      if (!opts || !opts.noScroll) window.scrollTo(0, 0);
    }
    controls.querySelector(".cl-back").addEventListener("click", function () { go(current - 1); });
    controls.querySelector(".cl-next").addEventListener("click", function () {
      if (current === sections.length - 1) { location.href = catalog; } else { go(current + 1); }
    });
    items.forEach(function (a, i) { a.addEventListener("click", function (e) { e.preventDefault(); go(i); }); });

    function fromHash() {
      if (!document.body.contains(article)) return;
      var h = decodeURIComponent(location.hash.replace(/^#/, ""));
      if (/^\d+$/.test(h)) { go(parseInt(h, 10), { keepHash: true }); return; }
      if (h) {
        var target = document.getElementById(h);
        if (target) {
          var idx = sections.findIndex(function (s) { return s.contains(target); });
          if (idx >= 0) { go(idx, { keepHash: true, noScroll: true }); setTimeout(function () { target.scrollIntoView(); }, 30); return; }
        }
      }
      var saved = parseInt(load("codelab-step") || "0", 10);
      go(isNaN(saved) ? 0 : saved, { noScroll: true });
    }
    if (window.__clHashHandler) window.removeEventListener("hashchange", window.__clHashHandler);
    window.__clHashHandler = fromHash;
    window.addEventListener("hashchange", fromHash);
    // Links to a step or anchor on THIS page: "#3", "foundations.html#3", "#some-heading".
    // Material's instant navigation turns same-page links into history.pushState (no
    // hashchange event), so we catch them first, in the capture phase.
    function samePageTarget(a) {
      var href = a.getAttribute("href");
      if (!href || a.target === "_blank") return null;
      var url;
      try { url = new URL(href, location.href); } catch (e) { return null; }
      if (url.origin !== location.origin || !url.hash) return null;
      var here = location.pathname.replace(/index\.html$/, ""), there = url.pathname.replace(/index\.html$/, "");
      if (here !== there) return null;
      return decodeURIComponent(url.hash.slice(1));
    }
    function onLinkClick(e) {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      var a = e.target.closest && e.target.closest("a[href]");
      if (!a || !document.body.contains(article) || a.classList.contains("headerlink")) return;
      var id = samePageTarget(a);
      if (id === null) return;
      if (/^\d+$/.test(id)) {
        e.preventDefault(); e.stopPropagation();
        go(parseInt(id, 10));
        return;
      }
      var t = document.getElementById(id);
      if (!t) return;
      var idx = sections.findIndex(function (s) { return s.contains(t); });
      if (idx < 0) return;
      e.preventDefault(); e.stopPropagation();
      if (idx !== current) go(idx, { noScroll: true });
      history.replaceState(null, "", "#" + id);
      setTimeout(function () { t.scrollIntoView(); }, 30);
    }
    if (window.__clLinkHandler) window.removeEventListener("click", window.__clLinkHandler, true);
    window.__clLinkHandler = onLinkClick;
    window.addEventListener("click", onLinkClick, true);
    if (window.__clPopHandler) window.removeEventListener("popstate", window.__clPopHandler);
    window.__clPopHandler = fromHash;
    window.addEventListener("popstate", fromHash);
    document.addEventListener("keydown", function (e) {
      if (e.target.closest && e.target.closest("input, textarea, [contenteditable]")) return;
      if (e.altKey || e.ctrlKey || e.metaKey) return;
      if (e.key === "ArrowRight" && e.shiftKey) go(current + 1);
      if (e.key === "ArrowLeft" && e.shiftKey) go(current - 1);
    });

    CL = {
      sections: sections,
      refreshNav: function () {
        sections.forEach(function (s, i) {
          var tasks = s.querySelectorAll(".admonition.step:not(.extra), details.step:not(.extra)");
          var done = s.querySelectorAll(".admonition.step.is-done:not(.extra), details.step.is-done:not(.extra)");
          items[i].classList.toggle("complete", tasks.length > 0 && done.length === tasks.length);
        });
      }
    };
    fromHash();
    return CL;
  }

  /* ------------------------------------------------------------------ tasks */
  function initTasks(article) {
    var scopes = CL ? CL.sections : [article];
    var globalIndex = 0;
    scopes.forEach(function (scope) {
      var steps = Array.prototype.slice.call(scope.querySelectorAll(".admonition.step, details.step"));
      if (!steps.length) return;
      var core = steps.filter(function (s) { return !s.classList.contains("extra"); });

      var bar = document.createElement("div");
      bar.className = "course-progress";
      bar.innerHTML = '<div class="cp-label"><span class="cp-text"></span><button class="cp-reset" type="button">Reset</button></div>' +
        '<div class="cp-track"><div class="cp-fill"></div></div>';
      var anchor = scope.querySelector(CL ? "h2" : "h1");
      if (anchor && anchor.nextSibling) anchor.parentNode.insertBefore(bar, anchor.nextSibling); else scope.prepend(bar);

      function refresh() {
        var done = core.filter(function (s) { return s.classList.contains("is-done"); }).length;
        bar.querySelector(".cp-text").textContent = done === core.length
          ? "All " + core.length + " tasks done. Nice work!" : done + " of " + core.length + " tasks done";
        bar.querySelector(".cp-fill").style.width = (core.length ? Math.round(done / core.length * 100) : 0) + "%";
        bar.classList.toggle("complete", done === core.length);
        if (CL) CL.refreshNav();
      }

      var n = 0;
      steps.forEach(function (s, i) {
        var id = globalIndex++;
        var title = s.querySelector(".admonition-title, summary");
        var isExtra = s.classList.contains("extra");
        if (!isExtra) n += 1;
        if (title && !title.querySelector(".step-num")) {
          var num = document.createElement("span");
          num.className = "step-num";
          num.textContent = isExtra ? "Extra" : "Task " + n + " of " + core.length;
          title.prepend(num);
        }
        var btn = document.createElement("button");
        btn.type = "button"; btn.className = "step-done";
        s.appendChild(btn);
        function paint() {
          var d = s.classList.contains("is-done");
          btn.innerHTML = d ? "&#10003; Done" : "Mark as done";
          btn.setAttribute("aria-pressed", d ? "true" : "false");
        }
        if (load("task:" + id) === "1") s.classList.add("is-done");
        paint();
        btn.addEventListener("click", function () {
          s.classList.toggle("is-done");
          save("task:" + id, s.classList.contains("is-done") ? "1" : null);
          paint(); refresh();
          if (s.classList.contains("is-done")) {
            var next = steps[i + 1];
            if (next && !next.classList.contains("is-done")) next.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        });
        s.dataset.taskId = id;
      });
      bar.querySelector(".cp-reset").addEventListener("click", function () {
        steps.forEach(function (s) {
          s.classList.remove("is-done"); save("task:" + s.dataset.taskId, null);
          var b = s.querySelector(".step-done"); if (b) b.innerHTML = "Mark as done";
        });
        refresh();
      });
      refresh();
    });
  }

  /* ------------------------------------------------------------------ widgets */
  // Flip cards: <div class="flipcards"><div class="flip"><div class="front">..</div><div class="back">..</div></div></div>
  function initFlip(root) {
    root.querySelectorAll(".flipcards").forEach(function (group) {
      var cards = group.querySelectorAll(".flip");
      cards.forEach(function (c, i) {
        if (c.dataset.ready) return;
        c.dataset.ready = "1";
        c.setAttribute("tabindex", "0"); c.setAttribute("role", "button");
        var hint = document.createElement("div");
        hint.className = "flip-hint";
        hint.textContent = (i + 1) + " of " + cards.length + " · Click to flip";
        c.appendChild(hint);
        function toggle() { c.classList.toggle("flipped"); }
        c.addEventListener("click", toggle);
        c.addEventListener("keydown", function (e) { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggle(); } });
      });
    });
  }

  // Quiz: <div class="quiz" data-answer="b"><p class="q">..</p><button data-opt="a">..</button>..<div class="explain">..</div></div>
  function initQuiz(root) {
    root.querySelectorAll(".quiz").forEach(function (q) {
      if (q.dataset.ready) return;
      q.dataset.ready = "1";
      var explain = q.querySelector(".explain");
      q.querySelectorAll("button[data-opt]").forEach(function (b) {
        b.type = "button";
        b.addEventListener("click", function () {
          q.querySelectorAll("button[data-opt]").forEach(function (x) { x.classList.remove("right", "wrong"); });
          var ok = b.dataset.opt === q.dataset.answer;
          b.classList.add(ok ? "right" : "wrong");
          if (ok && explain) explain.classList.add("show");
          var fb = q.querySelector(".feedback");
          if (!fb) { fb = document.createElement("p"); b.parentNode.insertBefore(fb, explain || null); }
          fb.textContent = ok ? "Correct!" : "Not quite. Try another option.";
          fb.className = "feedback " + (ok ? "ok" : "no");
        });
      });
    });
  }

  // Hotspots: <div class="hotspots"><div class="hs-stage"><img ..><button class="hs" style="left:10%;top:20%" data-title data-text>1</button></div><div class="hs-panel"></div></div>
  function initHotspots(root) {
    root.querySelectorAll(".hotspots").forEach(function (h) {
      if (h.dataset.ready) return;
      h.dataset.ready = "1";
      var panel = h.querySelector(".hs-panel"), spots = h.querySelectorAll(".hs");
      spots.forEach(function (s) {
        s.type = "button";
        s.addEventListener("click", function () {
          spots.forEach(function (x) { x.classList.remove("active"); });
          s.classList.add("active");
          if (panel) panel.innerHTML = "<strong>" + s.dataset.title + "</strong><br>" + s.dataset.text;
        });
      });
      if (panel && !panel.innerHTML.trim()) panel.innerHTML = "<em>Select each numbered marker to learn more.</em>";
    });
  }

  function init() {
    CL = null;
    document.body.classList.remove("codelab-mode");
    var root = document.querySelector(".md-content") || document.body;
    var article = root.querySelector("article") || root;
    initCodelab(article);
    initTasks(article);
    initFlip(root);
    initQuiz(root);
    initHotspots(root);
    renderDiagrams(root);
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(init);
  } else if (document.readyState !== "loading") {
    init();
  } else {
    document.addEventListener("DOMContentLoaded", init);
  }
})();
