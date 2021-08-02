# makesite.awk
Loops through the files in `input_dir` (`./src` by default) and outputs the processed files into `output_dir` (`./site` by default).

Only modifies `.md` files.  Everything else is just copied from `input_dir` to `output_dir`.

## Usage
```
awk -f makesite.awk
```
Alternately, set the file executable:
```
chmod +x makesite.awk
./makesite.awk
```
By default expects a `./src` directory and `./template.html` to exist, then deletes `./site` directory and rebuilds it with the output.


## Thoughts on the Implementation
Very simple implementation; only uses the BEGIN pattern.

Reads `./template.html` file line by line, makes substitution of {{date}}/{{curr_date}}, saves the template lines.

Wipes out the `output_dir` and then loops through `input_dir`.  Any subdirectories found in `input_dir` are recreated and filenames are stored in `files[]`.

Loops through `files[]`.  If the file does not have a `.md` extension, then it is copied to `output_dir`.

If is an `.md` file, then the template is looped through line by line and printed into the output file.  When the {{content}} string is found the `.md` file's contents are processed by the external utility specified by `md2html` and dumped into that line in the output file. 

Probably better if the modified dates for file in the `input_dir` are compared with `output_dir` and only newer files are updated.  Maybe next revision. 
