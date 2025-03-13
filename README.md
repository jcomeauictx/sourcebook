# sourcebook

A project to automate the process of making a book out of a git repository

For a start, it just prints up some numbered source files for taking to a
coffeeshop and doing some offline coding.

DeepSeek gave me the first few lines of tex code.

# developer's notes
* [including markdown with `\markdownInput{filename}`](https://www.overleaf.com/learn/how-to/Writing_Markdown_in_LaTeX_Documents)
* [writing book with LaTeX](https://www.overleaf.com/learn/latex/Sections_and_chapters)
* [need to run pdflatex *twice* for Contents to be populated](https://tex.stackexchange.com/a/301109/215508)
* Amazon Kindle cover requirements:
    - jpeg or TIFF
    - image ratio 1.6:1, ideally 2560px height by 1600 px width
    - 72 DPI
    - RGB colors
    - less than 50MB
* [Amazon cover calculator](https://kdp.amazon.com/en_US/cover-calculator),
  figure 9.25" height and 12.25 plus spine for width. For the spine, there's
  a "spine margin" of .062 inches on each side of the spine proper, called the
  "spine safe area", so the minimum spine is 0.124 inches. The number of
  pages determines the spine safe area, but it's not linear; 100 pages is only
  .1 inch, but 200 is .325, and 500 is 1.001 inches, all using plain white
  paper.
