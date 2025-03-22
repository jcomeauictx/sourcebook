# sourcebook

A project to automate the process of making a book out of a git repository

At the start, it just printed up some numbered source files for taking to a
coffeeshop and doing some offline coding. Now it builds entire books, ready
for upload to Amazon Kindle Direct Publishing (KDP).

DeepSeek gave me the first few lines of tex code, and since then it has grown
rapidly.

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

  Thus, in fact, the calculation *is* linear, and the spine margin is a
  myth. If you divide the "spine shown" column by the number of pages,
  the result in all of the above cases is almost exactly .00225 inches.
* Check the Makefile for whiteout options when text bleeds into the
  margins. (Now gets run by default as of 2025-03-19).
* TeX markdown cannot properly process `[text](url)` constructs with
  newlines anywhere within, but github markdown can.
* to get table to show up correctly in both github and TeX, without turning
  the text above into a header, there must be an empty space (not a line
  of hyphens, which tells github the above text is a new section header), and
  something (I used a line of hyphens below, but a space might work as well)
  which prevents github (and possibly TeX as well) from incorporating text
  below the table into table cells.
* Books with a large number of pages and listings of files with many lines
  may affect the margins. The margins specified by the geometry package
  `margin`, `hmargin` and `vmargin`, or `top`, `bottom`, `left`, and `right`,
  will not necessarily be honored. Adding what Amazon calls a "gutter" margin,
  and geometry calls `bindingoffset`, complicates matters further. The listings
  package puts line numbers into the margin space, so enough extra room
  needs to be allocated. Also, the "linewidth" specifier in the listings
  package will override the right margin. Finally, the margin calculated
  by clip.ps will chop the right border off listings if the linewidth is
  set too high.
* While watching a build for errors, you can grep out uninteresting lines, e.g.,
  `tail -f casperscript.letter.log | egrep -v '^(Underfull |$| ?\[[0-9]*\]$)'`
* This might help with tinyseg.js:
  <https://bbs.archlinux.org/viewtopic.php?id=72327>
* With a repository of sufficient size, such as casperscript, you will run out
  of memory. Change the defaults to something higher, these are my current
  choices:

    ```
    $ diff /usr/share/texlive/texmf-dist/web2c/texmf.cnf.orig /usr/share/texlive/texmf-dist/web2c/texmf.large.2025-03-22.cnf
    795,797c795,797
    < main_memory = 5000000 % words of inimemory available; also applies to inimf&mp
    < extra_mem_top = 0     % extra high memory for chars, tokens, etc.
    < extra_mem_bot = 0     % extra low memory for boxes, glue, breakpoints, etc.
    ---
    > main_memory = 8000000 % words of inimemory available; also applies to inimf&mp
    > extra_mem_top = 100000000     % extra high memory for chars, tokens, etc.
    > extra_mem_bot = 200000000     % extra low memory for boxes, glue, breakpoints, etc.
    811c811
    < hash_extra = 600000
    ---
    > hash_extra = 6000000
    815c815
    < pool_size = 6250000
    ---
    > pool_size = 62500000
    818c818
    < string_vacancies = 90000
    ---
    > string_vacancies = 900000
    820c820
    < max_strings = 500000
    ---
    > max_strings = 5000000
    830c830
    < buf_size = 200000
    ---
    > buf_size = 2000000
    ```
