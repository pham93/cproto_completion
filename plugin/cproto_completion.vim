" GET the current directory
" Get the current buffer
" check if cpp or h are the same
" IF a buffer is not in the buffer list, open it
" Write the definition in it
"
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
    let currBuff = bufname("%")
    let buffname = ""
    if match(currBuff,".cpp") >= 0
        let buffname = substitute(currBuff,".cpp",".h","")
    elseif match(currBuff,".h") >= 0
        let buffname = currBuff[:len(currBuff) - 3]
        let buffname = buffname.".cpp"
    elseif match(currBuff, ".hpp") >= 0
        let buffname = substitute(currBuff,".hpp",".cpp","")
    else
        return -1
    endif
    let splitpath = split(buffname,"/")
    let buff = splitpath[len(splitpath) -1]
    let path = splitpath[:len(splitpath) - 2]
    let abs_path = ""
    for fold in path
        let abs_path = abs_path . "/" . fold
    endfor
    let file = 0
    if len(splitpath) > 1
        let file = globpath(abs_path,buff,'\n')
    else
        let file = globpath(".",buff,'\n')
    endif

    if len(file) >= 1
        echo "go here"
        let curline = getline(".")
        if bufname(buffname) == buffname
            call SetCurrentDef(currBuff, buffname, curline) 
        else
            call SetCurrentDef(currBuff, buffname, curline)
            execute ":e ".buffname
        endif
    else
        echo buffname." doesn't exist"
    endif
endfunction

function! WriteClass(class_name, impl_name)
python << Endpython
import vim
class_name = vim.eval("a:class_name")
class_no_ex = class_name.split(".")[0]
impl_name = vim.eval("a:impl_name")
class_open = open(class_name, "w")
impl_open = open(impl_name, "w")
impl_open.write('#include "{}"\n'.format(class_name))
class_open.write('class {}'.format(class_no_ex) + "{\n" + 'public:\n    {}();\n'.format(class_no_ex))
class_open.write('private:\n};')

class_open.close()
impl_open.close()
Endpython
endfunction

function! GenerateClass(class_name)
    let file = globpath('.',a:class_name,'\n')
    if len(file) <= 0
        let impl_name = substitute(a:class_name,".h",".cpp","") 
        execute "!touch ".a:class_name." ".impl_name
        call WriteClass(a:class_name, impl_name)
    endif
endfunction