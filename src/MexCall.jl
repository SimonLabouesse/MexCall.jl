module MexCall
#
#
#
export mxInit, mxAlloc, mxDestroy, mxFreeArray, mxCall, @mxAddMexFile, mxGetPointer, mxSetPointer, enumMxFunc, convInput, getMxPenv
#
#
#
typealias mxArray Ptr{Void};
#
#
include("load.jl");
#
#
#
#
function mxFind(path=nothing)
    if(path!=nothing) 
        try  
            global libmx = dlopen("$path\\libmx.dll");
            ENV["path"]="$(ENV["path"]);$path";  # set the environment variable to include the folder in the path.
            println("Found libmx @ $path. Path added to environment.");
        catch
            println("libmx not found in the user provided location: @ $path . Try to call mxInit(\"path_to_libmx.dll_in_matlab_folder\")");
        end
        return
    end
    if( ismatch(r"([^;]+MATLAB[^;])"i,ENV["path"]) )
        path = match(r"([^;]+MATLAB[^;]+bin)"i,ENV["path"]) ;
        if(path==nothing) 
            path = match(r"([^;]+MATLAB[^;]+bin\win32)"i,ENV["path"]) ;    
        end
        #
        #
        if(path!=nothing) 
            path = path.match;
            # path = replace(path,"\\","/");
            #println(path);
            try  # is the library directly in the path?
                global libmx = dlopen("$path\\libmx.dll");
                println("Found libmx @ $path");
            catch # maybe it is in the win64 or win32 sub directory?
                try  
                    global libmx = dlopen("$path\\win64\\libmx.dll");
                    ENV["path"]="$(ENV["path"]);$path\\win64";  # set the environment variable to include the folder in the path.
                    println("Found libmx @ $path\\win64. Path added to environment.");
                catch
                    try
                        global libmx = dlopen("$path\\win32\\libmx.dll");
                        ENV["path"]="$(ENV["path"]);$path\\win32";  # set the environment variable to include the folder in the path.
                        println("Found libmx @ $path\\win32. Path added to environment.");
                     catch
                        println("libmx not found in @ $path . Try to call mxInit(\"path_to_libmx.dll_in_matlab_folder\")");
                    end
                end
            end
        else
                println("No matlab in this computer. Try to call mxInit(\"path_to_libmx.dll_in_matlab_folder\")");
        end
    else
        println("No matlab in this computer. Try to call mxInit(\"path_to_libmx.dll_in_matlab_folder\")");
    end
end
#
#
#
#
function mxInit(path=nothing)
    mxFind(path);
    mxLoad();
    global mxPenv = Array(Ptr{mxArray},0);
    global enumMxFunc = (String=>String)[];
    global enumType = (DataType=>Int64)[Bool => 3 ,
                                      Char => 4 ,
                                      Float64 => 6 ,
                                      Float32 => 7 ,
                                      Int8 => 8 ,
                                      Uint8 => 9,
                                      Int16 => 10,
                                      Uint16 => 11,
                                      Int32 => 12,
                                      Uint32 => 13,
                                      Int64 => 14 ,
                                      Uint64 => 15    ];
end
#
#
macro mxAddMexFile(completeFileName, nlhs)
    #
    if(!isa(completeFileName,ASCIIString))
        error("First argument of completeFileName must be a string.");
    end
    if(!isa(nlhs,Int))
        error("Second argument of completeFileName must be a integer.");
    elseif(nlhs<0)
        print("nlhs set by default to 10\n");
        nlhs=10;
    end
    #    
    local name = match(r"(\w+)\.\w{2,6}$", completeFileName)
    name = name.captures[1]
    enumMxFunc[name] = string(completeFileName)
    #esc( :( println($name)))
    global symFunc = symbol(name)
    #esc(:( $symFunc(args...;nlhs=$nlhs) = mxCall($completeFileName,nlhs, args) ))
    esc(quote
        function $symFunc(args...;nlhs=$nlhs)
            return mxCall($completeFileName,nlhs, args);
        end
        end);
    #
    #
end
#
#
function getMxPenv()
    return mxPenv;
end
#
function mxPush(plhs::Array{mxArray})
    for element in plhs
        push!(mxPenv,element);
    end
end
#
function mxAlloc(mType::DataType, dims::Int...)
    aType = Ptr{mType};
    size = prod(dims);
    a = ccall(mxCalloc,Ptr{Void},(Int,Int),size,sizeof(mType));
    a = convert(aType,a);
    a = pointer_to_array(a,size);
    a = reshape(a,dims);
    #mxPush(a);
    #println(a);
    return a;
end
#
#
function mxFreeArray(ptr)
    if(typeof(ptr)<:Array)
        ccall(mxFree,Void, (Ptr{Void},),pointer(a));
        #println("free");
    end    
end
    #
function mxDestroy()
	if (isdefined(mxPenv, 1) && mxPenv != C_NULL); 
	    global mxPenv=C_NULL;
        end
end
#
#
function mxGetPointer(anMxArray,aType=Float32)
    ret = ccall(mxGetPr, Ptr{aType}, (mxArray,), anMxArray);
    println(ret);
    ret = convert(Ptr{aType},ret);
end
#
#
#
function mxSetPointer(anMxArray,aPtr)
   ccall(mxSetPr,Void,(mxArray,Ptr{Void}),anMxArray,aPtr);
end
#
#
#
#
##################
    mxInit();    #
##################
#
#
#
function mxCall(method::String, nlhs, args...)
    (nrhs, prhs) = convInput(args);
    plhs = Array(mxArray,nlhs);
    #
    if( haskey(enumMxFunc,method))
        mexFile = enumMxFunc[method];
    else
        mexFile = method;
    end
    libmxfile = dlopen(mexFile);
    mexFunction = dlsym(libmxfile, :mexFunction);
    #println("Will call ccall now \n");
    #println(nrhs);

    ccall(mexFunction,Void, (Int,Ptr{mxArray},Int,Ptr{mxArray}), nlhs, plhs, nrhs, prhs);
    #println("End of ccall \n");
    
    retsTest = extractOutput(nlhs, plhs);    
    retsTest
    #return (nlhs,plhs);
    #
end
#
#
#
function convInput(varargs...)
    #
    #println("ConvInput\n");
    #println(varargs);
    #println(length(varargs[1]));
    if( length(varargs[1])!=0)
        args = varargs[1][1];
        argtypes=typeof(args);
        #println(argtypes);
        nrhs = length(argtypes);
        #println(nrhs);
        prhs = Array(mxArray,nrhs);
        #println("Start for loop\n");
        for id = 1:nrhs
            argtype = argtypes[id];
            #
            #switch type input
            if(argtype == UTF8String)
                #println("Start UTF8String");
                prhs[id] = ccall(mxCreateString,mxArray, (Ptr{Uint8},),args[id]);
                #println("End UTF8String \n");
            elseif(argtype == ASCIIString)
                #println("Start ASCIIString");
                prhs[id] = ccall(mxCreateString,mxArray, (Ptr{Uint8},),convert(UTF8String,args[id]));
                #println("End ASCIIString \n");
            elseif(argtype <: Array)
                if( ndims(args[id])==2 )
                    #println("Start Array");
                    #see example arrayFillSetData.c                    
                    prhs[id] = ccall(mxCreateNumericMatrix,mxArray, (Int, Int, Int, Int),0, 0, enumType[ eltype(args[id])],0) ;
                    #println("num type");
                    #println(eltype(args[id]));
                    #println(enumType[ eltype(args[id])]);
                    M = size(args[id],1);
                    N = size(args[id],2);
                    ccall(mxSetM,Void,(mxArray, Int,),prhs[id] ,M);
                    ccall(mxSetN,Void,(mxArray, Int,),prhs[id] ,N);
                    temp = mxAlloc(eltype(args[id]), M, N);
                    #println(size(args[id]));
                    #println("Malloc done");
                    for i=1 : M*N
                        temp[i] = args[id][i];
                    end
                    #println(temp);
                    #
                    mxSetPointer(prhs[id],pointer(temp));   #args[id]))
                    #ccall(mxSetPr,Void,(mxArray,Ptr{Void}),prhs[id],pointer(temp));
                    #println("End Array\n");
                else
                    #println("Dim diff 2");
                    #println(ndims(args[id]));
                end
            elseif(argtype <: Number)
                #println("not tested");
                argTemp = convert(Float64, args[id]);
                #println("Start number");
                prhs[id] = ccall(mxCreateDoubleScalar,mxArray,(Float64,), argTemp);
                #println("End number\n");
            end
            #
            #
        end
        #println("End for loop\n");
    else
        nrhs=0;
        prhs = C_NULL;
    end
    return (nrhs, prhs);
    #
end
#

#
function test(tst, el) ccall(tst, Bool, (mxArray,), el) end
function oftype(tp, el) ccall(mxGetPr, Ptr{tp}, (mxArray,), el) end
#

mxTypes = [
  mxIsDouble => Float64,
  mxIsSingle => Float32,
  mxIsInt8   => Int8,
  mxIsInt16  => Int16,
  mxIsInt32  => Int32,
  mxIsInt64  => Int64,
  mxIsUint8  => Uint8,
  mxIsUint16 => Uint16,
  mxIsUint32 => Uint32,
  mxIsUint64 => Uint64,
]
#

function extractOutput(nlhs, output::Array{mxArray})
    #
    #println("extractOutput\n");
    #println(output);
    ret = Array(Any,nlhs);
    for i = 1:nlhs
        #println(i);
        if( (output[i]!= C_NULL) && (!ccall(mxIsEmpty, Bool, (mxArray,), output[i]))  )
            #println("start for loop");
            #println(output[i]);
            M= ccall(mxGetM,Int,(mxArray,), output[i]);
            N = ccall(mxGetN,Int,(mxArray,), output[i]);
            #println(M);
            #println(N);
            if(test(mxIsNumeric, output[i])) # numeric
                curType = Any; # write only variable??
                #println(collect(mxTypes));
                println("\n\n");
                for (k, v) in collect(mxTypes)
                    #println(k);
                    #println(v);                   
                    if test(k, output[i])
                        #
                        println(v);
                        #
                        #ret[i] = reshape(pointer_to_array(oftype(Float64, output[i]), M*N), M, N);   This line "work" but not the next one and ptinln(v) display Float64.
                        ret[i] = reshape(pointer_to_array(oftype(v, output[i]), M*N), M, N);
                        break
                    end
                end
                #println(ret[i]);
            elseif (test(mxIsChar, output[i])) # string
                buflen = M*N + 1;
                ret[i] = Array(Uint8, buflen);
                statut = ccall(mxGetString, Int, (mxArray, Ptr{Uint8}, Int), output[i], ret[i], buflen); # write only variable??
                ret[i] = UTF8String(ret[i]);
            end
            #    
            #println("end for loop");
        end
        #
        return ret;
    end
    #
end



end # module
