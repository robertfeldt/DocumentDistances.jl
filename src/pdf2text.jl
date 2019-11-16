# We register our dependence on tika jar as a data dependency
function register_tika_app_jar_dependency()
    register(DataDep(
        "tika-app-1.22.jar",
        "Apache Tika App Jar file version 1.22",
        ["http://it.apache.contactlab.it/tika/tika-app-1.22.jar"],
        "d7219709abc547136fa5fca17632a85fe1cd36dc08cb4031957e3c9a836543e2"))
end

withtxtext(fn) = first(splitext(fn)) * ".txt"

function pdf2text_apache_tika(filename::String, 
    txtfilename::String = withtxtext(filename))

    tikajardir = datadep"tika-app-1.22.jar"
    tikajarpath = joinpath(tikajardir, "tika-app-1.22.jar")

    println("Converting $filename to $txtfilename using Apache Tika v1.22")
    try
        run(pipeline(`/usr/bin/env java -jar $tikajarpath -t $filename`, txtfilename))
    catch err
        error("Error when running Apache Tika to convert to txt file")
        @show err
    end

    if !isfile(txtfilename)
        error("No text file created by Apache Tika!")
    end

    return txtfilename
end

pdf2text(filename::String, txtfilename::String = withtxtext(filename)) = 
    pdf2text_apache_tika(filename, txtfilename)

function walkfilesmatching(fn::Function, dir::String, regexp::Regex; recursive = true)
    for (root, dirs, files) in walkdir(dir)
        if recursive
            for dir in dirs
                walkfilesmatching(fn, joinpath(root, dir), regexp; recursive = recursive)
            end
        end
        for file in files
            filepath = joinpath(root, file)
            if occursin(regexp, filepath)
                fn(filepath)
            end
        end
    end
end

isnewer(filepath1, filepath2) = stat(filepath1).mtime > stat(filepath2).mtime

# Convert all pdf files in a dir to txt files. Iff recursive we traverse also into subdirs and
# iff onlyifnew we only convert if there is not already a text file with the same name
# which is older than the pdf file. Returns the paths to all text files.
function convert_pdf_files_to_txt(dirname::String; recursive = true, onlyifnew = true)
    count = converted = 0
    alltextfiles = String[]
    walkfilesmatching(dirname, r".*\.pdf$"; recursive = recursive) do pdffilepath
        count += 1
        txtfilepath = withtxtext(pdffilepath)
        push!(alltextfiles, txtfilepath)
        if onlyifnew == false || !isfile(txtfilepath) || isnewer(pdffilepath, txtfilepath)
            converted += 1
            pdf2text_apache_tika(pdffilepath)
        end
    end
    println("Found $count pdf files and converted $converted of them.")
    return alltextfiles
end