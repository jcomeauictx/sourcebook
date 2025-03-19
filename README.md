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
    * jpeg or TIFF
    * image ratio 1.6:1, ideally 2560px height by 1600 px width
    * 72 DPI
    * RGB colors
    * less than 50MB
* [Amazon cover calculator](https://kdp.amazon.com/en_US/cover-calculator),
  for a nominally 6x9 book, with .125" bleed and .125" margin in each dimension,
  figure 9.25" height and 12.25" plus spine for width. For the spine, there's
  a "spine margin" of .031 inches on each side of the spine proper, called the
  "spine safe area", so the minimum spine is theoretically 0.062"; but in
  reality, the calculator shows a spine width of 0.054 inches for the minimal
  24 page book, for a total width of 12.304". The number of pages determines
  the spine safe area, but it's not linear; 24 and 50 pages both show as 0,
  for example, but the total width is different.
  |Pages|Spine safe area|Spine expected|Spine shown|Total width shown|
  |-----|---------------|--------------|-----------|-----------------|
  |   24|              0|          .062|       .054|           12.304|
  |   50|              0|          .062|       .113|           12.363|
  |   75|           .044|          .106|       .169|           12.419|
  |  100|           .100|          .162|       .225|           12.475|
  |  200|           .325|          .387|       .450|           12.700|
  |  500|          1.001|         1.063|      1.126|           12.376|
  --------------------------------------------------------------------
  Thus, in fact, the calculation *is* linear, and the spine margin is a
  myth. If you divide the "spine shown" column by the number of pages,
  the result in all of the above cases is almost exactly .00225 inches.
* Check the Makefile for whiteout options when text bleeds into the
  margins.
