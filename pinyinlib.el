;;; pinyinlib.el --- Convert first letter of Pinyin to Simplified/Traditional Chinese characters  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;                              ______________

;;                               PINYINLIB.EL

;;                               Junpeng Qiu
;;                              ______________


;; Table of Contents
;; _________________

;; 1 Functions
;; .. 1.1 `pinyinlib-build-regexp-char'
;; .. 1.2 `pinyinlib-build-regexp-string'
;; 2 Packages that Use This Library
;; 3 Acknowledgment
;; 4 Contribute


;; [[file:https://melpa.org/packages/pinyinlib-badge.svg]]
;; [[file:https://stable.melpa.org/packages/pinyinlib-badge.svg]]

;; Library for converting first letter of Pinyin to Simplified/Traditional
;; Chinese characters.


;; [[file:https://melpa.org/packages/pinyinlib-badge.svg]]
;; https://melpa.org/#/pinyinlib

;; [[file:https://stable.melpa.org/packages/pinyinlib-badge.svg]]
;; https://stable.melpa.org/#/pinyinlib


;; 1 Functions
;; ===========

;; 1.1 `pinyinlib-build-regexp-char'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   `pinyinlib-build-regexp-char' converts a letter to a regular
;;   expression containing all the Chinese characters whose pinyins start
;;   with the letter.  It accepts five parameters:
;;   ,----
;;   | char &optional no-punc-p tranditional-p only-chinese-p mixed-p
;;   `----

;;   The first parameter `char' is the letter to be converted.  The latter
;;   four parameters are optional.
;;   - If `no-punc-p' is `t': it will not convert English punctuations to
;;     Chinese punctuations.

;;   - If `traditional-p' is `t': traditional Chinese characters are used
;;     instead of simplified Chinese characters.

;;   - If `only-chinese-p' is `t': the resulting regular expression doesn't
;;     contain the English letter `char'.

;;   - If `mixed-p' is `t': the resulting regular expression will mix
;;     traditional and simplified Chinese characters. This parameter will take
;;     precedence over `traditional-p'.

;;   When converting English punctuactions to Chinese/English punctuations,
;;   it uses the following table:
;;    English Punctuation  Chinese & English Punctuations 
;;   -----------------------------------------------------
;;    .                    。.                            
;;    ,                    ，,                            
;;    ?                    ？?                            
;;    :                    ：:                            
;;    !                    ！!                            
;;    ;                    ；;                            
;;    \\                   、\\                           
;;    (                    （(                            
;;    )                    ）)                            
;;    <                    《<                            
;;    >                    》>                            
;;    ~                    ～~                            
;;    '                    ‘’「」'                      
;;    "                    “”『』\"                     
;;    *                    ×*                            
;;    $                    ￥$                            


;; 1.2 `pinyinlib-build-regexp-string'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   It is same as `pinyinlib-build-regexp-char', except that its first
;;   parameter is a string so that it can convert a sequence of letters to
;;   a regular expression.


;; 2 Packages that Use This Library
;; ================================

;;   - [ace-pinyin]
;;   - [evil-find-char-pinyin]
;;   - [find-by-pinyin-dired]
;;   - [pinyin-search]


;; [ace-pinyin] https://github.com/cute-jumper/ace-pinyin

;; [evil-find-char-pinyin]
;; https://github.com/cute-jumper/evil-find-char-pinyin

;; [find-by-pinyin-dired]
;; https://github.com/redguardtoo/find-by-pinyin-dired

;; [pinyin-search] https://github.com/xuchunyang/pinyin-search.el


;; 3 Acknowledgment
;; ================

;;   - The ASCII char to Chinese character
;;     table(`pinyinlib--simplified-char-table' in code) is from
;;     [https://github.com/redguardtoo/find-by-pinyin-dired].
;;   - @erstern adds the table for traditional Chinese characters.


;; 4 Contribute
;; ============

;;   Contributions are always welcome.  If you want to add some common
;;   pinyin related functions that might be useful for other packages,
;;   please send me a PR.

;;; Code:

(load-file "shuangpin-dict.el")

(defvar pinyinlib--punctuation-alist
  '((?. . "[。.]")
    (?, . "[，,]")
    (?? . "[？?]")
    (?: . "[：:]")
    (?! . "[！!]")
    (?\; . "[；;]")
    (?\\ . "[、\\]")
    (?\( . "[（(]")
    (?\) . "[）)]")
    (?\< . "[《<]")
    (?\> . "[》>]")
    (?~ . "[～~]")
    (?\' . "[‘’「」']")
    (?\" . "[“”『』\"]")
    (?* . "[×*]")
    (?$ . "[￥$]")))

(defun pinyinlib-build-regexp-char
    (char &optional no-punc-p tranditional-p only-chinese-p mixed-p)
  (let ((diff (- char ?a))
        regexp)
    (if (or (>= diff 26) (< diff 0))
        (or (and (not no-punc-p)
                 (assoc-default
                  char
                  pinyinlib--punctuation-alist))
            (regexp-quote (string char)))
      (setq regexp
            (if mixed-p
                (concat (nth diff pinyinlib--traditional-char-table)
                        (nth diff pinyinlib--simplified-char-table))
              (nth diff
                   (if tranditional-p
                       pinyinlib--traditional-char-table
                     pinyinlib--simplified-char-table))))
      (if only-chinese-p
          (if (string= regexp "")
              regexp
            (format "[%s]" regexp))
        (format "[%c%s]" char
                regexp)))))

(defun pinyinlib-build-regexp-string
    (str &optional no-punc-p tranditional-p only-chinese-p mixed-p)
  (mapconcat (lambda (c) (pinyinlib-build-regexp-char
                      c no-punc-p tranditional-p only-chinese-p mixed-p))
             str
             ""))

(provide 'pinyinlib)
;;; pinyinlib.el ends here
