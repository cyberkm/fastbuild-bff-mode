# fastbuild-bff-mode

Emacs major mode for [FASTBuild](https://www.fastbuild.org/) BFF (Build Configuration) files with syntax highlighting and context-aware completion.

## Features

- **Syntax highlighting** for:
  - Functions (`Library`, `Executable`, `ObjectList`, `Compiler`, etc.)
  - Preprocessor directives (`#include`, `#if`, `#define`, etc.)
  - Properties (`.Compiler`, `.CompilerOptions`, etc.)
  - Variable references (`$VarName$`)
  - Built-in variables (`_CURRENT_BFF_DIR_`, `_WORKING_DIR_`, etc.)
  - Keywords (`true`, `false`, `function`, `in`)
  - Platform symbols (`__WINDOWS__`, `__LINUX__`, `__OSX__`)

- **Smart indentation** based on bracket nesting

- **Context-aware completion** - when inside a function body, only relevant properties are suggested:
  - Inside `Library() { }` → `.Compiler`, `.LibrarianOptions`, `.PCHInputFile`, etc.
  - Inside `Executable() { }` → `.Linker`, `.LinkerOutput`, `.Libraries`, etc.
  - Inside `Unity() { }` → `.UnityInputPath`, `.UnityOutputPattern`, etc.

- **Electric pairs** for automatic bracket/quote closing

## Installation

### Manual

```elisp
;; Add to your init.el
(add-to-list 'load-path "/path/to/fastbuild-bff-mode")
(require 'fastbuild-bff-mode)
```

### use-package (manual)

```elisp
(use-package fastbuild-bff-mode
  :load-path "/path/to/fastbuild-bff-mode")
```

### MELPA (coming soon)

```elisp
(use-package fastbuild-bff-mode
  :ensure t)
```

## Usage

The mode activates automatically for `.bff` files.

Trigger completion with your preferred completion frontend:
- Built-in: `M-x completion-at-point` or `C-M-i`
- [company-mode](https://company-mode.github.io/): completion popup appears automatically
- [corfu](https://github.com/minad/corfu): completion popup appears automatically

## Customization

```elisp
;; Change indentation offset (default: 4)
(setq fastbuild-bff-indent-offset 2)
```

## License

GPL-3.0-or-later
