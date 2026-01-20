use File::Basename;
use Cwd;

my $pwd = getcwd();

# Enable auto-flushing for print output
$| = 1;  # This forces immediate output to the console

# Default list of files to be processed.
# @default_files = ("main", "second", "third", "etc.")
@default_files = ("");

# The first parameter is the name of one of the system's environment variables for search paths.
# The remaining parameters are values that should be in the variable.
ensure_path('TEXINPUTS', "$pwd/", "$pwd/assets//", "$pwd/build//");
ensure_path('BIBINPUTS', "../assets"); # Relative to $out_dir

# Increase log line width to 1000 characters
$ENV{max_print_line} = $log_wrap = 1000;

# Under what conditions to run bibtex or biber.
#  - 0: never use BibTeX or biber; never delete .bbl files in a cleanup.
#  - 1: only use bibtex or biber if the bib files exist; never delete .bbl files in a cleanup.
#  - 1.5: only use bibtex or biber if the bib files exist; conditionally delete .bbl files in a cleanup (i.e., delete themonly when the bib files all exist).
#  - 2: run bibtex or biber whenever it appears necessary to update the bbl files, without testing for the existence of the bib files; always delete .bbl files in a cleanup.
$bibtex_use = 2;

# Extra extensions of files for latexmk to remove when any of the clean-up options (-c or -C) is  selected.
$clean_ext .= " acn acr alg glg glo gls nav ist snm vrb _minted-%R/* _minted-%R/";
# This contains a list of extensions for files that are generated during processing, and that should be deleted during a main clean up operation, as invoked by the command line option -c.
# push @generated_exts, 'nav', 'snm';

# The directory in which auxiliary files (aux, log, etc) are to be written by a run of *latex.
$aux_dir = "build";

# Use of this option results in a file of extension .fls containing a list of the files that these programs have read and written.
# Latexmk will then use this file to improve its detection of source files and generated files after a run of *latex.
$recorder = 1;

# This variable specifies the directory in which output files are to be written by a run of *latex.
$out_dir = "build";

# If zero, do NOT generate a pdf version of the document.
# If equal to 1, generate a pdf version of the document using pdflatex, using the command specified by the $pdflatex variable.
# If equal to 2, generate a pdf version of the document from the ps file, by using the command specified by the $ps2pdf variable.
# If equal to 3, generate a pdf version of the document from the dvi file, by using the command specified by the $dvipdf variable.
# If equal to 4, generate a pdf version of the document using lualatex, using the command specified by the $lualatex variable.
# If equal to 5, generate a pdf version (and an xdv version) of the document using xelatex, using the commands specified by the $xelatex and xdvipdfmx variables.
$pdf_mode = 5;

# Specifies the command line for the LaTeX processing program of when the xelatex program is called for.
$xelatex = 'xelatex %O -interaction=nonstopmode -halt-on-error --shell-escape %S';

# Viewer auto-reloads when PDF changes
# $pdf_update_method = 2;

# The command to invoke a pdf-previewer.
$pdf_previewer = 'xdg-open';
# $pdf_previewer = 'papers %O %S';
# $pdf_previewer = 'env GSK_RENDERER=cairo papers %O %S';
# $pdf_previewer = 'gio open %S';

# $pdf_update_method = 1;               # latexmk restarts viewer if needed
# $pdf_previewer     = 'start xdg-open %O %S';

# https://www.ctan.org/tex-archive/support/latexmk/example_rcfiles
# https://mirror.easyname.at/ctan/support/latexmk/example_rcfiles/glossaries_latexmkrc
# A method to configure latexmk to use a custom dependency is to use the subroutines that allow convenient manipulations of the custom dependency list.
# These are
#   add_cus_dep( fromextension, toextension, must, subroutine )
#   remove_cus_dep( fromextension, toextension )
#   show_cus_dep()
# The arguments are as follows:
#  - from extension:
#      The extension of the file we are converting from (e.g. "fig").
#      It is specified without a period.
#  - to extension:
#      The extension of the file we are converting to (e.g. "eps").
#      It is specified without a period.
#  - must:
#      If non-zero, the file from which we are converting must exist, if it doesn't exist latexmk will give an error message and exit unless the -f option is specified.
#      If must is zero and the file we are converting from doesn't exist, then no action is taken.
#      Generally, the appropriate value of must is zero.
#  - function:
#      The name of the subroutine that latexmk should call to perform the file conversion.
#      The first argument to the subroutine is the base name of the file to be converted without any extension.
#      The subroutines are declared in the syntax of Perl.
#      The function should return 0 if it was successful and a nonzero number if it failed.
#  Naturally add_cus_dep adds a custom dependency with the specified from and to extensions.
#  If a custom dependency has been previously defined (e.g., in an rcfile that was read earlier), then it is replaced by the new one.
add_cus_dep( 'acn', 'acr', 0, 'makeglossaries' );
add_cus_dep( 'glo', 'gls', 0, 'makeglossaries' );

sub makeglossaries {
    my ($basename, $path) = fileparse( $_[0] );
    my @args = ( "-q", "-d", $path, $basename );
    if ($silent) { unshift @args, "-q"; }
    return system "makeglossaries", "-d", "$path", $basename
}

# Detect if 'handout' or 'all' is passed as a command
my $mode = '';

# Go through the arguments and check for custom modes
for (my $i = 0; $i <= $#ARGV; $i++) {
    if ( $ARGV[$i] eq 'handout' ) {
        $mode = 'handout';
        splice(@ARGV, $i, 1);  # Remove 'handout' from the argument list
        last;
    }
}

# If 'handout' mode, adjust xelatex command with jobname
if ( $mode eq 'handout' ) {
    $jobname = "\%A" . "-handout";
    $xelatex = 'xelatex %O -shell-escape "\\PassOptionsToClass{handout}{beamer} \\input{%S}"';
}

# Custom Dependency: TikZ Externalization
# Compiles standalone .tikz files to PDF using XeLaTeX.
add_cus_dep( 'tikz', 'pdf', 0, 'tikz2pdf' );

sub tikz2pdf {
    my $base = shift;
    my $dir  = dirname($base);
    my $cmd  = "xelatex -shell-escape -interaction=nonstopmode -halt-on-error -output-directory=\"$dir\" \"$base.tikz\"";
    return system($cmd);
}