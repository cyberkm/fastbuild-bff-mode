;;; fastbuild-bff-mode.el --- Major mode for FASTBuild BFF files -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pavel Bibergal

;; Author: Pavel Bibergal <cyberkm@gmail.com>
;; Maintainer: Pavel Bibergal <cyberkm@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages, tools, build
;; URL: https://github.com/cyberkm/fastbuild-bff-mode
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for editing FASTBuild BFF (Build Configuration) files.
;; FASTBuild is a high performance build system supporting distributed
;; compilation and caching.
;;
;; Features:
;; - Syntax highlighting for BFF syntax
;; - Smart indentation
;; - Keyword completion
;; - Context-aware property completion (e.g., inside Library() suggests
;;   .Compiler, .CompilerOptions, etc.)
;;
;; Usage:
;; Add to your init.el:
;;   (require 'fastbuild-bff-mode)
;; Or with use-package:
;;   (use-package fastbuild-bff-mode)
;;
;; The mode will automatically activate for .bff files.
;;
;; For more information about FASTBuild, see:
;; https://www.fastbuild.org/

;;; Code:

(require 'cl-lib)

;;; Customization

(defgroup fastbuild-bff nil
  "Major mode for FASTBuild BFF files."
  :group 'languages
  :prefix "fastbuild-bff-")

;;; Constants - Functions and Properties

(defconst fastbuild-bff-functions
  '("Alias" "Compiler" "Copy" "CopyDir" "CSAssembly" "DLL" "Error"
    "Exec" "Executable" "ForEach" "If" "Library" "ListDependencies"
    "ObjectList" "Print" "RemoveDir" "Settings" "Test" "TextFile"
    "Unity" "Using" "VCXProject" "VSProjectExternal" "VSSolution"
    "XCodeProject")
  "List of FASTBuild built-in functions.")

(defconst fastbuild-bff-directives
  '("#define" "#undef" "#if" "#else" "#endif" "#import" "#include" "#once")
  "List of FASTBuild preprocessor directives.")

(defconst fastbuild-bff-builtin-variables
  '("_CURRENT_BFF_DIR_" "_FASTBUILD_VERSION_" "_FASTBUILD_VERSION_STRING_"
    "_FASTBUILD_EXE_PATH_" "_WORKING_DIR_")
  "List of FASTBuild built-in variables.")

(defconst fastbuild-bff-keywords
  '("true" "false" "in" "not" "function")
  "List of FASTBuild keywords.")

(defconst fastbuild-bff-predefined-symbols
  '("__WINDOWS__" "__LINUX__" "__OSX__" "exists" "file_exists")
  "List of FASTBuild predefined symbols and functions.")

(defconst fastbuild-bff-function-properties
  '(("Library" . (".Compiler" ".CompilerOptions" ".CompilerOutputPath"
                  ".CompilerOutputExtension" ".CompilerOutputPrefix"
                  ".Librarian" ".LibrarianOptions" ".LibrarianType"
                  ".LibrarianOutput" ".LibrarianAdditionalInputs"
                  ".LibrarianAllowResponseFile" ".LibrarianForceResponseFile"
                  ".CompilerInputPath" ".CompilerInputPattern"
                  ".CompilerInputPathRecurse" ".CompilerInputExcludePath"
                  ".CompilerInputExcludedFiles" ".CompilerInputExcludePattern"
                  ".CompilerInputFiles" ".CompilerInputFilesRoot"
                  ".CompilerInputUnity" ".CompilerInputAllowNoFiles"
                  ".CompilerInputObjectLists" ".AllowCaching" ".AllowDistribution"
                  ".Preprocessor" ".PreprocessorOptions" ".CompilerForceUsing"
                  ".PCHInputFile" ".PCHOutputFile" ".PCHOptions"
                  ".PreBuildDependencies" ".ConcurrencyGroupName" ".Environment" ".Hidden"))
    ("ObjectList" . (".Compiler" ".CompilerOptions" ".CompilerOutputPath"
                     ".CompilerOutputExtension" ".CompilerOutputKeepBaseExtension"
                     ".CompilerOutputPrefix" ".CompilerInputPath" ".CompilerInputPattern"
                     ".CompilerInputPathRecurse" ".CompilerInputExcludePath"
                     ".CompilerInputExcludedFiles" ".CompilerInputExcludePattern"
                     ".CompilerInputFiles" ".CompilerInputFilesRoot"
                     ".CompilerInputUnity" ".CompilerInputAllowNoFiles"
                     ".CompilerInputObjectLists" ".AllowCaching" ".AllowDistribution"
                     ".Preprocessor" ".PreprocessorOptions" ".CompilerForceUsing"
                     ".PCHInputFile" ".PCHOutputFile" ".PCHOptions"
                     ".PreBuildDependencies" ".ConcurrencyGroupName" ".Hidden"))
    ("Executable" . (".Linker" ".LinkerOutput" ".LinkerOptions" ".Libraries"
                     ".Libraries2" ".LinkerLinkObjects" ".LinkerAssemblyResources"
                     ".LinkerStampExe" ".LinkerStampExeArgs" ".LinkerType"
                     ".LinkerAllowResponseFile" ".LinkerForceResponseFile"
                     ".PreBuildDependencies" ".ConcurrencyGroupName" ".Environment"))
    ("DLL" . (".Linker" ".LinkerOutput" ".LinkerOptions" ".Libraries"
              ".Libraries2" ".LinkerLinkObjects" ".LinkerAssemblyResources"
              ".LinkerStampExe" ".LinkerStampExeArgs" ".LinkerType"
              ".LinkerAllowResponseFile" ".LinkerForceResponseFile"
              ".PreBuildDependencies" ".ConcurrencyGroupName" ".Environment"))
    ("Compiler" . (".Executable" ".ExtraFiles" ".CompilerFamily" ".AllowCaching"
                   ".AllowDistribution" ".ExecutableRootPath" ".SimpleDistributionMode"
                   ".CustomEnvironmentVariables" ".ClangRewriteIncludes"
                   ".ClangGCCUpdateXLanguageArg" ".VS2012EnumBugFix" ".Environment"
                   ".AllowResponseFile" ".ForceResponseFile"
                   ".UseLightCache_Experimental" ".UseRelativePaths_Experimental"
                   ".UseDeterministicPaths_Experimental" ".SourceMapping_Experimental"
                   ".ClangFixupUnity_Disable"))
    ("Unity" . (".UnityInputPath" ".UnityInputExcludePath" ".UnityInputExcludePattern"
                ".UnityInputPattern" ".UnityInputPathRecurse" ".UnityInputFiles"
                ".UnityInputExcludedFiles" ".UnityInputIsolatedFiles"
                ".UnityInputObjectLists" ".UnityInputIsolateWritableFiles"
                ".UnityInputIsolateWritableFilesLimit" ".UnityInputIsolateListFile"
                ".UnityOutputPath" ".UnityOutputPattern" ".UnityNumFiles"
                ".UnityPCH" ".PreBuildDependencies" ".Hidden"
                ".UseRelativePaths_Experimental"))
    ("Alias" . (".Targets" ".Hidden"))
    ("Copy" . (".Source" ".Dest" ".SourceBasePath" ".PreBuildDependencies"))
    ("CopyDir" . (".SourcePaths" ".SourcePathsPattern" ".SourcePathsRecurse"
                  ".SourceExcludePaths" ".Dest" ".PreBuildDependencies"))
    ("Exec" . (".ExecExecutable" ".ExecInput" ".ExecInputPath" ".ExecInputPattern"
               ".ExecInputPathRecurse" ".ExecInputExcludePath" ".ExecInputExcludedFiles"
               ".ExecInputExcludePattern" ".ExecOutput" ".ExecArguments"
               ".ExecWorkingDir" ".ExecReturnCode" ".ExecUseStdOutAsOutput"
               ".ExecAlways" ".ExecAlwaysShowOutput" ".PreBuildDependencies"
               ".ConcurrencyGroupName" ".Environment"))
    ("Test" . (".TestExecutable" ".TestOutput" ".TestInput" ".TestInputPath"
               ".TestInputPattern" ".TestInputPathRecurse" ".TestInputExcludePath"
               ".TestInputExcludedFiles" ".TestInputExcludePattern" ".TestArguments"
               ".TestWorkingDir" ".TestTimeOut" ".TestAlwaysShowOutput"
               ".PreBuildDependencies" ".ConcurrencyGroupName" ".Environment"))
    ("Settings" . (".Environment" ".CachePath" ".CachePathMountPoint"
                   ".CachePluginDLL" ".CachePluginDLLConfig" ".Workers"
                   ".WorkerConnectionLimit" ".DistributableJobMemoryLimitMiB"
                   ".ConcurrencyGroups"))
    ("TextFile" . (".TextFileOutput" ".TextFileInputStrings" ".TextFileAlways"))
    ("CSAssembly" . (".Compiler" ".CompilerOptions" ".CompilerOutput"
                    ".CompilerInputPath" ".CompilerInputPattern"
                    ".CompilerInputPathRecurse" ".CompilerInputExcludePath"
                    ".CompilerInputExcludedFiles" ".CompilerInputExcludePattern"
                    ".CompilerInputFiles" ".CompilerReferences"
                    ".PreBuildDependencies"))
    ("VCXProject" . (".ProjectOutput" ".ProjectInputPaths" ".ProjectInputPathsExclude"
                    ".ProjectInputPathsRecurse" ".ProjectPatternToExclude"
                    ".ProjectAllowedFileExtensions" ".ProjectFiles"
                    ".ProjectFilesToExclude" ".ProjectBasePath" ".ProjectFileTypes"
                    ".ProjectConfigs" ".ProjectReferences" ".ProjectProjectReferences"
                    ".ProjectProjectImports" ".ProjectGuid" ".DefaultLanguage"
                    ".ApplicationEnvironment" ".ProjectSccEntrySAK"
                    ".ProjectBuildCommand" ".ProjectRebuildCommand"
                    ".ProjectCleanCommand" ".Output" ".OutputDirectory"
                    ".IntermediateDirectory" ".BuildLogFile" ".LayoutDir"
                    ".LayoutExtensionFilter" ".PreprocessorDefinitions"
                    ".IncludeSearchPath" ".ForcedIncludes" ".AssemblySearchPath"
                    ".ForcedUsingAssemblies" ".AdditionalOptions"
                    ".LocalDebuggerCommand" ".LocalDebuggerCommandArguments"
                    ".LocalDebuggerWorkingDirectory" ".LocalDebuggerEnvironment"
                    ".RemoteDebuggerCommand" ".RemoteDebuggerCommandArguments"
                    ".RemoteDebuggerWorkingDirectory" ".PlatformToolset"
                    ".DeploymentType" ".DeploymentFiles" ".RootNamespace"))
    ("VSSolution" . (".SolutionOutput" ".SolutionProjects" ".SolutionConfigs"
                    ".SolutionFolders" ".SolutionDependencies" ".SolutionBuildProject"
                    ".SolutionDeployProjects" ".SolutionMinimumVisualStudioVersion"
                    ".SolutionVisualStudioVersion"))
    ("XCodeProject" . (".ProjectOutput" ".ProjectInputPaths" ".ProjectInputPathsExclude"
                       ".ProjectInputPathsRecurse" ".ProjectPatternToExclude"
                       ".ProjectAllowedFileExtensions" ".ProjectFiles"
                       ".ProjectFilesToExclude" ".ProjectBasePath" ".ProjectConfigs"
                       ".XCodeBuildToolPath" ".XCodeBuildToolArgs"
                       ".XCodeBuildWorkingDir" ".XCodeDocumentVersioning"
                       ".XCodeCommandLineArguments" ".XCodeCommandLineArgumentsDisabled"
                       ".XCodeOrganizationName"))
    ("ListDependencies" . (".Targets" ".ListDependenciesOutput"))
    ("RemoveDir" . (".RemovePaths" ".RemovePathsRecurse" ".RemovePatterns"
                    ".RemoveExcludePaths" ".PreBuildDependencies"))
    ("Error" . (".ErrorMessage"))
    ("Print" . (".PrintMessage")))
  "Alist mapping FASTBuild functions to their properties.")

;;; Syntax Table

(defvar fastbuild-bff-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments: // and ;
    (modify-syntax-entry ?/ ". 124" table)
    (modify-syntax-entry ?* ". 23b" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\; "<" table)
    ;; Strings
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?' "\"" table)
    ;; Escape character
    (modify-syntax-entry ?^ "\\" table)
    ;; Punctuation
    (modify-syntax-entry ?. "." table)
    (modify-syntax-entry ?$ "." table)
    (modify-syntax-entry ?# "." table)
    ;; Parentheses
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table)
  "Syntax table for `fastbuild-bff-mode'.")

;;; Font Lock (Syntax Highlighting)

(defface fastbuild-bff-function-face
  '((t :inherit font-lock-function-name-face))
  "Face for FASTBuild function names."
  :group 'fastbuild-bff)

(defface fastbuild-bff-property-face
  '((t :inherit font-lock-variable-name-face))
  "Face for FASTBuild property names (starting with dot)."
  :group 'fastbuild-bff)

(defface fastbuild-bff-directive-face
  '((t :inherit font-lock-preprocessor-face))
  "Face for FASTBuild preprocessor directives."
  :group 'fastbuild-bff)

(defface fastbuild-bff-variable-ref-face
  '((t :inherit font-lock-variable-name-face :weight bold))
  "Face for FASTBuild variable references ($Var$)."
  :group 'fastbuild-bff)

(defface fastbuild-bff-builtin-face
  '((t :inherit font-lock-builtin-face))
  "Face for FASTBuild built-in variables."
  :group 'fastbuild-bff)

(defvar fastbuild-bff-font-lock-keywords
  `(;; Preprocessor directives
    (,(concat "^\\s-*\\(" (regexp-opt fastbuild-bff-directives) "\\)\\b")
     1 'fastbuild-bff-directive-face)
    ;; Built-in functions
    (,(concat "\\_<\\(" (regexp-opt fastbuild-bff-functions) "\\)\\s-*(")
     1 'fastbuild-bff-function-face)
    ;; User-defined functions
    ("\\<function\\s-+\\([A-Za-z_][A-Za-z0-9_]*\\)"
     1 'fastbuild-bff-function-face)
    ;; Keywords
    (,(concat "\\_<\\(" (regexp-opt fastbuild-bff-keywords) "\\)\\_>")
     1 'font-lock-keyword-face)
    ;; Predefined symbols
    (,(concat "\\_<\\(" (regexp-opt fastbuild-bff-predefined-symbols) "\\)\\_>")
     1 'font-lock-constant-face)
    ;; Built-in variables
    (,(concat "\\_<\\(" (regexp-opt fastbuild-bff-builtin-variables) "\\)\\_>")
     1 'fastbuild-bff-builtin-face)
    ;; Variable references: $VarName$
    ("\\$\\([A-Za-z_][A-Za-z0-9_]*\\)\\$"
     0 'fastbuild-bff-variable-ref-face)
    ;; Property/variable definitions: .PropertyName
    ("\\.\\([A-Za-z_][A-Za-z0-9_]*\\)"
     0 'fastbuild-bff-property-face)
    ;; Parent scope modifier: ^PropertyName
    ("\\^\\([A-Za-z_][A-Za-z0-9_]*\\)"
     0 'fastbuild-bff-property-face)
    ;; Numbers
    ("\\_<[0-9]+\\_>"
     0 'font-lock-constant-face)
    ;; Build-time substitutions: %1, %2, etc.
    ("%[0-9]+"
     0 'font-lock-constant-face))
  "Font lock keywords for `fastbuild-bff-mode'.")

;;; Indentation

(defcustom fastbuild-bff-indent-offset 4
  "Number of spaces for each indentation level in BFF files."
  :type 'integer
  :safe #'integerp
  :group 'fastbuild-bff)

(defun fastbuild-bff--in-string-p ()
  "Return non-nil if point is inside a string."
  (nth 3 (syntax-ppss)))

(defun fastbuild-bff--in-comment-p ()
  "Return non-nil if point is inside a comment."
  (nth 4 (syntax-ppss)))

(defun fastbuild-bff--line-scope-delta ()
  "Return net scope change from current line.
Positive = more opens than closes."
  (save-excursion
    (beginning-of-line)
    (let ((delta 0))
      ;; #if opens a scope
      (when (looking-at "^\\s-*#if\\b")
        (setq delta (1+ delta)))
      ;; #else closes one scope and opens another
      (when (looking-at "^\\s-*#else\\b")
        (setq delta (1+ delta)))
      ;; Count brackets
      (while (not (eolp))
        (cond
         ((fastbuild-bff--in-string-p) (forward-char 1))
         ((fastbuild-bff--in-comment-p) (end-of-line))
         ((memq (char-after) '(?\{ ?\[))
          (setq delta (1+ delta))
          (forward-char 1))
         ((memq (char-after) '(?\} ?\]))
          (setq delta (1- delta))
          (forward-char 1))
         (t (forward-char 1))))
      delta)))

(defun fastbuild-bff--prev-line-open-brace-content-column ()
  "If prev line has { or [ with content after, return column of content.
Returns nil if brace is closed on the same line or at end of line."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (let ((result nil)
          (line-end (line-end-position)))
      (while (and (not result) (< (point) line-end))
        (cond
         ((fastbuild-bff--in-string-p) (forward-char 1))
         ((fastbuild-bff--in-comment-p) (goto-char line-end))
         ((memq (char-after) '(?\{ ?\[))
          (let ((close-char (if (eq (char-after) ?\{) ?\} ?\])))
            (forward-char 1)
            (skip-chars-forward " \t")
            ;; Check if there's content and brace is NOT closed on same line
            (when (and (< (point) line-end)
                       (not (memq (char-after) '(?\} ?\]))))
              (let ((content-col (current-column))
                    (closed-on-line nil))
                ;; Scan rest of line to see if brace is closed
                (save-excursion
                  (while (and (not closed-on-line) (< (point) line-end))
                    (cond
                     ((fastbuild-bff--in-string-p) (forward-char 1))
                     ((eq (char-after) close-char)
                      (setq closed-on-line t))
                     (t (forward-char 1)))))
                (unless closed-on-line
                  (setq result content-col))))))
         (t (forward-char 1))))
      result)))

(defun fastbuild-bff--current-line-closes-p ()
  "Return non-nil if current line has a scope-closing token at start."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (or (eq (char-after) ?\})
        (eq (char-after) ?\])
        (looking-at "#\\(endif\\|else\\)\\b"))))

(defun fastbuild-bff--current-line-closes-brace-p ()
  "Return non-nil if current line has } or ] at start."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (memq (char-after) '(?\} ?\]))))

(defun fastbuild-bff--find-matching-open-brace-column ()
  "Find column of matching { or [ for } or ] on current line."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (when (memq (char-after) '(?\} ?\]))
      (let ((close-char (char-after))
            (open-char (if (eq (char-after) ?\}) ?\{ ?\[))
            (depth 1))
        (while (and (> depth 0) (not (bobp)))
          (forward-char -1)
          (unless (or (fastbuild-bff--in-string-p)
                      (fastbuild-bff--in-comment-p))
            (cond
             ((eq (char-after) close-char)
              (setq depth (1+ depth)))
             ((eq (char-after) open-char)
              (setq depth (1- depth))))))
        (when (= depth 0)
          (current-column))))))

(defun fastbuild-bff--current-line-starts-with-plus-p ()
  "Return non-nil if current line has + at start."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (eq (char-after) ?+)))

(defun fastbuild-bff--prev-line-plus-column ()
  "Return column of + if previous non-empty line has + at start.  Else nil."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (when (eq (char-after) ?+)
      (current-column))))

(defun fastbuild-bff--prev-line-equals-column ()
  "Return column of = if previous non-empty line has =.  Else nil."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (let ((limit (line-end-position)))
      (while (< (point) limit)
        (cond
         ((fastbuild-bff--in-string-p) (forward-char 1))
         ((fastbuild-bff--in-comment-p) (goto-char limit))
         ((eq (char-after) ?=)
          (setq limit (point)))  ; found it, exit loop
         (t (forward-char 1))))
      (when (eq (char-after) ?=)
        (current-column)))))

(defun fastbuild-bff--prev-line-is-continuation-p ()
  "Return non-nil if previous non-empty line has + at start."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (eq (char-after) ?+)))

(defun fastbuild-bff--prev-line-starts-with-close-brace-p ()
  "Return non-nil if previous non-empty line has } or ] at start."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (memq (char-after) '(?\} ?\]))))

(defun fastbuild-bff--find-opener-line-indent ()
  "Find indentation of line containing matching opener for prev line's closer.
Previous line must start with } or ]."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (when (memq (char-after) '(?\} ?\]))
      (let ((close-char (char-after))
            (open-char (if (eq (char-after) ?\}) ?\{ ?\[))
            (depth 1))
        (while (and (> depth 0) (not (bobp)))
          (forward-char -1)
          (unless (or (fastbuild-bff--in-string-p)
                      (fastbuild-bff--in-comment-p))
            (cond
             ((eq (char-after) close-char)
              (setq depth (1+ depth)))
             ((eq (char-after) open-char)
              (setq depth (1- depth))))))
        (when (= depth 0)
          ;; Return the indentation of the line containing the opener
          (current-indentation))))))

(defun fastbuild-bff--prev-line-ends-with-close-brace-p ()
  "Check if previous non-empty line ends with } or ]."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (end-of-line)
    (skip-chars-backward " \t")
    (and (not (bolp))
         (memq (char-before) '(?\} ?\])))))

(defun fastbuild-bff--find-opener-line-indent-from-end ()
  "Find indentation of opener's line for } or ] at end of prev line."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (end-of-line)
    (skip-chars-backward " \t")
    (when (and (not (bolp))
               (memq (char-before) '(?\} ?\])))
      (forward-char -1)  ; move onto the close brace
      (let ((close-char (char-after))
            (open-char (if (eq (char-after) ?\}) ?\{ ?\[))
            (depth 1))
        (while (and (> depth 0) (not (bobp)))
          (forward-char -1)
          (unless (or (fastbuild-bff--in-string-p)
                      (fastbuild-bff--in-comment-p))
            (cond
             ((eq (char-after) close-char)
              (setq depth (1+ depth)))
             ((eq (char-after) open-char)
              (setq depth (1- depth))))))
        (when (= depth 0)
          (current-indentation))))))

(defun fastbuild-bff--find-continuation-start ()
  "Go back to the line that started the continuation block.
Returns (indent . scope-delta) of that line."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    ;; Keep going back while lines start with +
    (while (and (not (bobp))
                (progn
                  (beginning-of-line)
                  (skip-chars-forward " \t")
                  (eq (char-after) ?+)))
      (forward-line -1)
      (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
        (forward-line -1)))
    ;; Now on the line that started the assignment
    (cons (current-indentation) (fastbuild-bff--line-scope-delta))))

(defun fastbuild-bff--calculate-indent ()
  "Calculate indentation for current line."
  (save-excursion
    (beginning-of-line)
    (cond
     ;; First line
     ((bobp) 0)
     ;; Current line starts with + - align with prev + or prev =
     ((fastbuild-bff--current-line-starts-with-plus-p)
      (or (fastbuild-bff--prev-line-plus-column)
          (fastbuild-bff--prev-line-equals-column)
          (current-indentation)))
     ;; Current line is } or ] - align with matching { or [
     ((fastbuild-bff--current-line-closes-brace-p)
      (or (fastbuild-bff--find-matching-open-brace-column)
          0))
     ;; Current line is #endif or #else - dedent
     ((save-excursion
        (beginning-of-line)
        (skip-chars-forward " \t")
        (looking-at "#\\(endif\\|else\\)\\b"))
      (let ((prev-indent 0)
            (scope-delta 0))
        (save-excursion
          (forward-line -1)
          (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
            (forward-line -1))
          (setq prev-indent (current-indentation))
          (setq scope-delta (fastbuild-bff--line-scope-delta)))
        (max 0 (+ prev-indent (* scope-delta fastbuild-bff-indent-offset)
                  (- fastbuild-bff-indent-offset)))))
     ;; Previous line was continuation - find original scope
     ((fastbuild-bff--prev-line-is-continuation-p)
      (let* ((start-info (fastbuild-bff--find-continuation-start))
             (base-indent (car start-info))
             (scope-delta (cdr start-info)))
        (max 0 (+ base-indent (* scope-delta fastbuild-bff-indent-offset)))))
     ;; Previous line starts with } or ] - use opener's line indentation
     ((fastbuild-bff--prev-line-starts-with-close-brace-p)
      (or (fastbuild-bff--find-opener-line-indent) 0))
     ;; Previous line ends with } or ] - use opener's line indentation
     ((fastbuild-bff--prev-line-ends-with-close-brace-p)
      (or (fastbuild-bff--find-opener-line-indent-from-end) 0))
     ;; Previous line has { or [ with content - align with content
     ((fastbuild-bff--prev-line-open-brace-content-column))
     ;; Normal scope-based indentation
     (t
      (let ((prev-indent 0)
            (scope-delta 0))
        (save-excursion
          (forward-line -1)
          (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
            (forward-line -1))
          (setq prev-indent (current-indentation))
          (setq scope-delta (fastbuild-bff--line-scope-delta)))
        (max 0 (+ prev-indent (* scope-delta fastbuild-bff-indent-offset))))))))

(defun fastbuild-bff-indent-line ()
  "Indent current line as BFF code."
  (interactive)
  (let ((indent (fastbuild-bff--calculate-indent))
        (pos (- (point-max) (point))))
    (indent-line-to indent)
    (when (> (- (point-max) pos) (point))
      (goto-char (- (point-max) pos)))))

;;; Completion

(defun fastbuild-bff--get-enclosing-function ()
  "Return the name of the enclosing FASTBuild function, if any."
  (save-excursion
    (let ((depth 0)
          (func-name nil))
      (while (and (not func-name)
                  (not (bobp)))
        (backward-char 1)
        (cond
         ((fastbuild-bff--in-string-p) nil)
         ((fastbuild-bff--in-comment-p) nil)
         ((eq (char-after) ?\})
          (setq depth (1+ depth)))
         ((eq (char-after) ?\{)
          (if (> depth 0)
              (setq depth (1- depth))
            ;; Found opening brace at our level, look for function name
            (save-excursion
              (skip-chars-backward " \t\n")
              (when (eq (char-before) ?\))
                (backward-sexp)
                (skip-chars-backward " \t\n")
                (let ((end (point)))
                  (skip-chars-backward "A-Za-z0-9_")
                  (let ((name (buffer-substring-no-properties (point) end)))
                    (when (member name fastbuild-bff-functions)
                      (setq func-name name))))))))))
      func-name)))

(defun fastbuild-bff--get-all-properties ()
  "Return a list of all unique properties from all functions."
  (let ((props '()))
    (dolist (func-props fastbuild-bff-function-properties)
      (dolist (prop (cdr func-props))
        (unless (member prop props)
          (push prop props))))
    (sort props #'string<)))

(defun fastbuild-bff-completion-at-point ()
  "Completion-at-point function for FASTBuild BFF mode."
  (when (not (or (fastbuild-bff--in-string-p)
                 (fastbuild-bff--in-comment-p)))
    (let* ((end (point))
           (start (save-excursion
                    (skip-chars-backward "A-Za-z0-9_")
                    (point)))
           (prefix-char (and (> start (point-min))
                             (char-before start)))
           (in-function (fastbuild-bff--get-enclosing-function)))
      (cond
       ;; Property completion (starts with .)
       ((eq prefix-char ?.)
        (let ((completions
               (if in-function
                   (or (cdr (assoc in-function fastbuild-bff-function-properties))
                       (fastbuild-bff--get-all-properties))
                 (fastbuild-bff--get-all-properties))))
          (list start end
                (mapcar (lambda (c)
                          (if (string-prefix-p "." c)
                              (substring c 1)
                            c))
                        completions)
                :exclusive 'no)))
       ;; Directive completion (starts with #)
       ((eq prefix-char ?#)
        (list start end
              (mapcar (lambda (d) (substring d 1)) fastbuild-bff-directives)
              :exclusive 'no))
       ;; General completion: functions and keywords (only with some prefix)
       ((> end start)
        (list start end
              (append fastbuild-bff-functions
                      fastbuild-bff-keywords
                      fastbuild-bff-builtin-variables)
              :exclusive 'no))))))

;;; Mode Definition

(defvar fastbuild-bff-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for `fastbuild-bff-mode'.")

;;;###autoload
(define-derived-mode fastbuild-bff-mode prog-mode "FASTBuild"
  "Major mode for editing FASTBuild BFF files.

\\{fastbuild-bff-mode-map}"
  :syntax-table fastbuild-bff-mode-syntax-table
  :group 'fastbuild-bff
  ;; Comments
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "\\(?://+\\|;+\\)\\s-*")
  ;; Font lock
  (setq-local font-lock-defaults '(fastbuild-bff-font-lock-keywords nil nil))
  ;; Indentation
  (setq-local indent-line-function #'fastbuild-bff-indent-line)
  ;; Completion
  (add-hook 'completion-at-point-functions #'fastbuild-bff-completion-at-point nil t)
  ;; Electric pairs
  (setq-local electric-pair-pairs '((?\{ . ?\})
                                    (?\( . ?\))
                                    (?\[ . ?\])
                                    (?\" . ?\")
                                    (?\' . ?\'))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bff\\'" . fastbuild-bff-mode))

(provide 'fastbuild-bff-mode)

;;; fastbuild-bff-mode.el ends here
