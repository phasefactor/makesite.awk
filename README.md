# makesite.awk
Loops through the files in `input_dir` (`./src` by default) and outputs the processed files into `output_dir` (`./site` by default).

Only modifies `.md` files.  Everything else is just copied from `input_dir` to `output_dir`.

Current version will react poorly if two or more of {{content}}, {{script}}, or {{style}} being on the same line of the template.

## Usage
```
awk -f makesite.awk
```
Alternately, set the file executable:
```
chmod +x makesite.awk
./makesite.awk
```
By default expects a `./src` directory and `./template.html` to exist.  Then  `./site` directory and subdirectories are built if needed.

Only files that have newer modified dates in the `input_dir` than in `output_dir` (or that do not exist in `output_dir`) are copied.

Expects a utility specified in the `md2html` variable to exist for converting MD to HTML. Something like [md2html.awk](https://github.com/quBASIC/md2html.awk).

If {{style}} or {{script}} are used in the template, then the `style_file` and `script_file` variables need to point somewhere (defaults are `./style.css` and `./script.js`).  Currently does not validate that the files exist.  If they are missing an error will appear in the console output and nothing in the output files.

## Thoughts on the Implementation
Very simple implementation; only uses the BEGIN pattern.

Loops through `input_dir`and any subdirectories, makes sure the directories exist in `output_dir`, and then any files found in `input_dir` that do not exist or are out of date have their filenames stored in `files[]`.

If `files[]` is non-empty, then read `./template.html` file line by line making substitutions for {{date}}/{{curr_date}}, saves the template into `template[]`.

Loops through `files[]`,  copy non-`.md` files to their destinations, and write `.md` files out as `.html`.

The template is looped through line by line and printed into the `.html` output file.  

When the {{content}} string is found the `.md` file's contents are processed by the external utility specified by `md2html` and dumped into that line in the output file. 

When the {{style}} or {{script}} strings are encountered the correct file is injected into the output.
