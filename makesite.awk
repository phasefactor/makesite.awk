#! /usr/bin/awk -f

# makesite.awk
#
# Recurse a directory converting MD to HTML and
# copying files into an output directory - v1
#
# Usage:
# awk -f makesite.awk 
# 
# WARNING - Blows up output_dir when run and re-builds
#           it from scratch!!!
#
# Expects directory specified in input_dir to exist.
# Expects a template at template_file with a line that
# contains the string {{content}} to output MD into.
# Expects some tool to exist at the path specified by
# md2html that takes in MD and returns HTML.
# {{date}} or {{curr_date}} in template inserts the 
# date in format specified.
# #####################################################


BEGIN {
    # setup globals
    # change these to reflect your environment
    input_dir     = "./src";
    output_dir    = "./site";
    template_file = "./template.html";
    md2html       = "./md2html.awk";
    
    # run date and store the result for later
    "date '+%Y-%m-%d'" | getline date_string;

    print "Reading in template (" template_file ").";
    while ((getline < template_file) > 0) {
        # if there are any global substitutions to make
        # this is the easiest spot to do them...
        if ($0 ~ /\{\{(curr_)?date\}\}/)
            gsub(/\{\{(curr_)?date\}\}/, date_string);
            
        # save the line
        template[++template_size] = $0;
    }
    close(template_file);
               
    # nuke and refresh the output directory
    print("Clearing output directory (" output_dir ")");
    
    system("rm -R '" output_dir "'");
    system("mkdir '" output_dir "'");
    
    # recursively descend the input directory
    print "Scanning input directory (" input_dir ")";
    cmd = "ls -1Rp " input_dir;
    
    while ((cmd | getline) > 0){
        if ($0 ~ /\:$/) {
            # is this a subdirectory of input_dir?
            subdir = substr( $0, (length(input_dir)+2), (length($0)-length(input_dir)-2) ) "/";
            print("Making directory: " output_dir "/" subdir);
            system("mkdir " output_dir "/" subdir);

        } else if ($0 ~ /^$/ || $0 ~ /\/$/) {
            # do nothing for current directory and blank lines    
        } else {
            # must be a file, add it to the list
            files[input_dir "/" subdir $0] = output_dir "/" subdir $0;
        }
    }
    close(cmd);
    
    # loop through files[]
    print("Starting to process files:");
    
    for (file in files) {
        # NOTE: file is the input file
        printf "Processing " file ": ";
        # files[file] is the output file
        output = files[file];
        
        # ignore images, css, movies, pdfs, etc
        if (output !~ /\.(md|MD|Md|mD)$/) {
            printf("ignored filetype, copying... ");
            system("cp '" file "' '" output "'");
            print("Done.");
            # go to next file
            continue;
        }
        
        # must be MD to process into HTML
        sub(/\.[a-zA-Z0-9]+$/, ".html", output)
        
        # some awks may fail to output if the file does
        # not exist already, uncomment if you need to...
        # system("touch '" output "'")

        # process the template line by line
        for (i=1; i<template_size; i++) { 
            # does line contain {{contents}} tag? 
            if (template[i] ~ /\{\{content(s)?\}\}/){
                # this actually replaces the whole template line
                # with the contents of the file... may not be ideal...
                # maybe substr() to grab what is before and after?
                if (file ~ /\.md$/) {
                    # push markdown through md2html.awk
                    printf("processing MarkDown... ");
                    system(md2html " '" file "' >> '" output "'");
                } else {
                    # if not we assume it is already HTML
                    printf("processing raw text... ");
                    system("cat '" file "' >> '" output "'");
                }               
            } else {
                # no replacement made, output as is
                print template[i] >> output;
            } 
        }
        # template is finished, 
        close(output);
        print("Done.");
    } # end of file in files loop
    
    print("All files processed.");
}
