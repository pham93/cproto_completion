" GET the current directory
" Get the current buffer
" check if cpp or h are the same
" IF a buffer is not in the buffer list, open it
" Write the definition in it
"
if !exists("g:cproto_headers_path")
    let g:cproto_headers_path = "headers"
endif 
if !exists("g:cproto_src_path")
    let g:cproto_src_path = "src"
endif

function! SetCurrentDef(currBuff, buffname, curline)
python << EOF
import vim
def appendToCPP(file_read, file_write, cur):
    for line in file_read:
        if "class" in line:
            cur = cur.split(" ")
            while '' in cur:
                cur.remove('')
            #class name{
            #class name: parent{
            #['class','name{']
            line = line.split(" ")
            line = line[1].replace("\n","")
            line = line[:-1]
            classcall = line + "::"
            prototype = cur[0] + " " + classcall + cur[1]
            for word in cur[2:]:
                prototype = prototype + " " + word
            prototype = prototype[:-1]
            file_write.write(prototype + "{\n}\n")
            break

def appendToH(buffname,cur):
    import fileinput
    # type class::method(arg, arg)
    cur = cur.split("::")
    #prototype = type class
    prototype = cur[0].split(" ")[0];
    for word in cur[1:]:
        prototype = prototype + " " + word
    prototype = prototype[:-1]
    if prototype[len(prototype) - 1] == ' ':
        prototype = '    ' + prototype[:-1] + ';'
    else:
        prototype = '    ' + prototype + ';'
    first_pulic = 0
    for line in fileinput.FileInput(buffname, inplace=1):
        #get rid of the \n character
        line = line[:-1]
        if "public:" in line:
            first_public = 1
            if first_public == 1:
                line = line + '\n' + prototype
                first_pulic == -1
        print line

cur = vim.eval("a:curline")
currBuff = vim.eval("a:currBuff")
buffname = vim.eval("a:buffname")
file = open(buffname, "a+")

H_or_CPP = open(currBuff, "r+")
if ".h" in currBuff:
    appendToCPP(H_or_CPP, file, cur)

if ".cpp" in currBuff:
    appendToH(buffname, cur)
file.close()
H_or_CPP.close()
EOF
endfunction

function! Def_complete()
    "make all path absolute
    "currBuff is the location of the current file
    let currBuff = bufname("%")
    "the path of the current buffer
    let currBuff_path = fnamemodify(currBuff,":p:h")
    "the name of the buffer
    let currBuff_name = fnamemodify(currBuff,":t")
    let currBuff_ex = fnamemodify(currBuff,":t:e")
    "dir/file.x ==> file.x ==> file
    let buffname = fnamemodify(currBuff,":t:r")
    if fnamemodify(currBuff,":e") == "cpp"
        let buffname = buffname.".h"
    elseif fnamemodify(currBuff,":e") == "h"
        let buffname = buffname.".cpp"
    elseif fnamemodify(currBuff,":e") == "hpp"
        let buffname = buffname. ".cpp"
    else
        return -1
    endif
    let abs_buffname = currBuff_path ."/".buffname

    let file = split(globpath(currBuff_path,buffname))
    if len(file) <= 0
        "go back to project's root dir
        let project_root = fnamemodify(currBuff_path,":h")
        if currBuff_ex == "h" 
            let file = split(globpath(project_root."/". g:cproto_src_path, buffname))
            let abs_buffname = project_root."/".g:cproto_src_path ."/".buffname
        else
            let file = split(globpath(project_root."/". g:cproto_headers_path, buffname))
            let abs_buffname = project_root."/".g:cproto_headers_path ."/".buffname
        endif
    endif
    echo abs_buffname
    if len(file) >= 1
        let curline = getline(".")
        if bufname(abs_buffname) == abs_buffname
            call SetCurrentDef(currBuff, abs_buffname, curline) 
        else
            call SetCurrentDef(currBuff, abs_buffname, curline)
            execute ":e " abs_buffname
        endif
    else
        echo buffname." doesn't exist"
    endif
endfunction

function! WriteClass(class_name, impl_name)
python << Endpython
import vim
class_name_abs = vim.eval("a:class_name")
class_name = vim.eval("fnamemodify(a:class_name,':t')")
class_no_ex = class_name.split(".")[0]
impl_name = vim.eval("a:impl_name")
class_open = open(class_name_abs, "w")
impl_open = open(impl_name, "w")
impl_open.write('#include "{}"\n'.format(class_name))
class_open.write('class {}'.format(class_no_ex) + "{\n" + 'public:\n    {}();\n'.format(class_no_ex))
class_open.write('private:\n};')
class_open.close()
impl_open.close()
Endpython
endfunction
function! GenerateClass(class_name, option)
    if a:option > 2
        return
    endif
    let header_file_path = fnamemodify(a:class_name,":h")
    let header_name = fnamemodify(a:class_name,":t")
    let file = []
    if a:option == 1
        let file = split(globpath(header_file_path ."/".g:cproto_headers_path,header_name,'\n'))
    else
        let file = split(globpath(header_file_path,header_name,'\n'))
    endif
    if len(file) == 0
        let impl_name = fnamemodify(header_name,":r").".cpp"
        if a:option == 1
            let header_file_name = header_file_path ."/". g:cproto_headers_path ."/" .header_name
            let src_file_name = header_file_path. "/".g:cproto_src_path."/".impl_name
            execute "!touch ".header_file_name " ".src_file_name
            call WriteClass(header_file_name, src_file_name)
        else
            let header_file_name = header_file_path. "/" .header_name 
            let src_file_name = header_file_path . "/" .impl_name
            execute "!touch ".header_file_name ." ".src_file_name
            call WriteClass(header_file_name, src_file_name)
        endif
    endif
endfunction
