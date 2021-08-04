#! /usr/bin/awk -f

# makesite.awk
#
# Recurse a directory converting MD to HTML and
# copying files into an output directory - v2
#
# Usage:
# awk -f makesite.awk 
# 
# Expects directory specified in input_dir to exist.
#
# Expects a template at template_file with a line that
# contains the string {{content}} to output MD into.
#
# Expects some tool to exist at the path specified by
# md2html that takes in MD and returns HTML.
#
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
               

    # recursively descend the input directory
    print "\nScanning input directory (" input_dir ")";
    cmd = "ls -1Rp " input_dir;
    
    while ((cmd | getline) > 0){
        # skip blank lines and subdirectories in the list
        if ($0 ~ /^$/ || /\/$/) {
            ;
        # subdirectory headers start with "./" and end with ":"
        } else if (/^(\.\/).+(\:)/) {
            sub(/\:$/, "")
            print "Scanning subdirectory (" $0 ")";

            subdir = substr($0, length(input_dir)+1);
            
            # does this directory exist in the output_dir?
            if ("stat -q -f '%m' '" output_dir subdir "'" | getline == 0) {
                system("mkdir '" output_dir subdir "'");
            }
        # should only be files, maybe add check for symlinks?    
        } else {
            # save the name into a temp variable
            name = $0;
            
            # is the input file a MD file? change extension
            if ($0 ~ /\.(md|MD|Md|mD)$/)
                sub(/\.(md|MD|Md|mD)$/, ".html", name);

            # get modified time on potential output file
            # -q suppresses errors messages,
            "stat -q -f '%m' '" output_dir subdir "/" name "'" | getline output_modified;

            # get modified time on input file
            "stat -f '%m' '" input_dir subdir "/" $0 "'" | getline input_modified;

            # is input file modified more recently?
            # or does the output not exist? (suppressed error returns 0)
            if (input_modified > output_modified || output_modified == 0) {
                print("  Identified file to process: " input_dir subdir "/" name);
                # save input and output file paths in associative array
                files[input_dir subdir "/" $0] = output_dir subdir "/" name;
            }
        }
    }
    close(cmd);

    # bail out if no files need to be updated
    if (length(files) == 0) {
        print("\nNo files found that need updates.\n");
        exit 0;
    }
    
    print "\nReading in template (" template_file ").";
    while ((getline < template_file) > 0) {
        # if there are any global substitutions to make
        # this is the easiest spot to do them...
        if ($0 ~ /\{\{(curr_)?date\}\}/)
            gsub(/\{\{(curr_)?date\}\}/, date_string);
            
        # save the line
        template[++template_size] = $0;
    }
    close(template_file);


    # loop through files[]
    print("\nStarting to process files:");
    
    for (file in files) {
        # NOTE: file is the input file
        printf "  Processing " file ": ";
        # files[file] is the output file
        output = files[file];

        # simply copy any non-MD input files
        if (file !~ /\.(md|MD|Md|mD)$/) {
            printf("copying... ");
            system("cp '" file "' '" output "'");
            print("Done.");
            # go to next file
            continue;
        }
        
        # process the template line by line
        for (i=1; i<template_size; i++) { 
            # does line contain {{contents}} tag? 
            if (template[i] ~ /\{\{content(s)?\}\}/){
                # this actually replaces the whole template line
                # with the contents of the file... may not be ideal...
                # maybe substr() to grab what is before and after?
                
                # push markdown through md2html.awk
                printf("processing MarkDown... ");
                system(md2html " '" file "' >> '" output "'");
            } else {
                # no replacement made, output as is
                print template[i] >> output;
            } 
        }
        
        # template is finished, 
        close(output);
        print("Done.");
    } # end of file in files loop
    
    print("\nAll files processed.\n");
}
