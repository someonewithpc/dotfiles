;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Hugo Sales"
      user-mail-address "hugo@hsal.es")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-material-dark)

(setq doom-font (font-spec :size 16))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type :relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;;

(setq-default tab-always-indent t)

;; ~~~~~~~~~~~ Slick Copy/Kill ~~~~~~~~~~~~
(defadvice kill-ring-save (before slick-copy activate compile)
  "When called interactively with no active region, copy a single
line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (message "Copied line")
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single
line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defun duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region                         ; Get region if active, otherwise line
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1))         ; Go to beginning of next line, or make a new one
                          (newline))))))
        (dotimes (i (abs (or n 1)))                      ; Insert N times, or once if not specified
          (insert text))))
    (if use-region nil                                   ; Only if we're working with a line (not a region)
      (let ((pos (- (point) (line-beginning-position)))) ; Save column
        (if (> 0 n)                                      ; Comment out original with negative arg
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))

(global-anzu-mode)

(map!
 :map 'global-map
 "M-S-<up>" #'drag-stuff-up
 "M-S-<down>" #'drag-stuff-down
 "M-<up>" #'scroll-up-line
 "M-<down>" #'scroll-down-line
 "C-c C-d" #'duplicate-line-or-region
 "C-j" #'join-line
 "M-/" #'company-complete-common-or-cycle
 ;; "C-;" #'iedit-mode
 "C-;" #'lsp-iedit-highlights
 "<mouse-6>" #'(lambda () (interactive) (scroll-right 3))
 "<mouse-7>" #'(lambda () (interactive) (scroll-left 3))
 [C-i] #'string-inflection-all-cycle
 "M-%" #'anzu-query-replace
 "C-M-%" #'anzu-query-replace-regexp
 ;; [remap comment-dwim] #'comment-dwim-2
 :map vertico-map
 "C-l" #'vertico-directory-up
 :map rjsx-mode-map
 "C-;" #'iedit-mode
 :map web-mode-map
 "C-;" #'iedit-mode
 )

(advice-add 'comment-dwim :override #'comment-dwim-2)

(setq backends '(company-gtags company-semantic company-capf company-dabbrev-code company-dabbrev))

(after! web-mode
  (set-company-backend! 'web-mode backends)
  (setq-hook! 'web-mode-hook
    web-mode-script-padding 0)

  (map! :map 'web-mode-map
        "M-/" #'company-complete-common-or-cycle
        )

  ;; ;; deletes any exact matches of the first entry with key "case-extra-offset"
  ;; (delq! "case-extra-offset" web-mode-indentation-params 'assoc)
  )

(after! rjsx-mode (set-company-backend! 'rjsx-mode backends))

(after! editorconfig
  (delete 'web-mode-script-padding (assoc 'web-mode editorconfig-indentation-alist))
  )

(after! emmet-mode
  (map!
   :map 'emmet-mode-keymap
   "<tab>" #'indent-for-tab-command
   )
  )

(set-register ?e '(file . (expand-file-name "~/.doom.d/init.el")))

(setq!
 scroll-preserve-screen-position nil)

(after! iedit
  (setq iedit-toggle-key-default nil)
  )

(after! php-mode
  (set-company-backend!
    'php-mode
    '(company-gtags
      company-semantic
      company-dabbrev-code
      company-dabbrev
      company-capf)
    )
  )

(defadvice isearch-update (before my-isearch-update activate)
  (sit-for 0)
  (if (and
       ;; not the scrolling command
       (not (eq this-command 'isearch-other-control-char))
       ;; not the empty string
       (> (length isearch-string) 0)
       ;; not the first key (to lazy highlight all matches w/o recenter)
       (> (length isearch-cmds) 2)
       ;; the point in within the given window boundaries
       (let ((line (count-screen-lines (point) (window-start))))
         (or (> line (* (/ (window-height) 4) 3))
             (< line (* (/ (window-height) 9) 1)))))
      (let ((recenter-position 0.3))
         (recenter '(4)))))

;(debug-watch 'consult-after-jump-hook)

(setq! consult-after-jump-hook 'recenter)

(after! highlight-indent-guides-mode
  (setq! highlight-indent-guides-method 'bitmap)
  (setq! highlight-indent-guides-bitmap-function 'hightligh-indent-guides--bitmap-dots)
  )

(after! lsp-mode
  (define-globalized-minor-mode lsp-headerline-breadcrumb-global-mode lsp-headerline-breadcrumb-mode
    (lambda () (lsp-headerline-breadcrumb-mode))
    )
  (lsp-headerline-breadcrumb-global-mode)
  (setq! lsp-headerline-arrow ">")
  )
