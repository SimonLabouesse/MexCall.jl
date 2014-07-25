module MexCall

export mxInit, mxAlloc, mxDestroy, mxFreeArray, mxCall, mxAddMexFile, enumMxFunc
typealias mxArray Ptr{Void};
#
include("load.jl");
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
    global mxPenv=Array(Ptr{mxArray},0);
    global enumMxFunc= (String=>String)[];
    global enumType=(DataType=>Int64)[Bool => 3 ,
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
function mxAddMexFile(completeFileName)
    #
    #completeFileName = "C:/cygwin64/home/Simon/work/juliaWork/mexFile/readkhoros_info.mexw64";
    #global enumMxFunc= (UTF8String=>UTF8String)[];
    #completeFileName = "~/work/juliaWork/mexFile/readkhoros_info.mexw64";
    fileName = match(r"(\w+)\.\w{2,6}$",completeFileName);
    fileName = fileName.captures[1];
    enumMxFunc[fileName] = completeFileName;
#
end
#
#
function mxPush(plhs::Array{mxArray})
    for array in plhs
        push!(mxPenv,array);
    end
end
#
#
function mxAlloc(mType::DataType, dims::Int...)
    aType = Ptr{mType};
    size = prod(dims);
    a = ccall(mxCalloc,Ptr{Void},(Int,Int),size,sizeof(mType));
    a = convert(aType,a);
    a = pointer_to_array(a,size);
    a = reshape(a,dims);
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
	if (!isdefined(mxPenv, 1) || mxPenv == C_NULL) ; error("Called destroy without initialising Mx"); end
	global mxPenv=C_NULL; 
end
#
#
#
#
function mxCall(method::String, rettypes::Tuple, argtypes::Tuple, rets, args )
    #println("\n\n\ndebut");
    #example readkhoros_info
    #method = "readkhoros_info";
    #
    #   
    if( haskey(enumMxFunc,method))
        mexFile = enumMxFunc[method];
    else
        mexFile = method;
    end
    #println(mexFile);
    libmxfile = dlopen(mexFile);
    #
    #
    mexFunction = dlsym(libmxfile, :mexFunction);
    nlhs = length(rettypes);
    nrhs = length(argtypes);
    #println(nlhs);
    #println(nrhs);
    plhs = Array(mxArray,nlhs);
    prhs = Array(mxArray,nrhs);
    for id = 1:nrhs
        argtype = argtypes[id];
        #
        #switch type input
        if(argtype == UTF8String)
            prhs[id] = ccall(mxCreateString,mxArray, (Ptr{Uint8},),args[id]);
        elseif (argtype <: Array)
            if( ndims(args[id])==2 )
                #see example arrayFillSetData.c
                prhs[id] = ccall(mxCreateNumericMatrix,mxArray, (Int, Int, Int, Int),0, 0, enumType[ eltype(args[id])],0) ;
                #println("num type");
                #println(enumType[ eltype(args[id])]);
                ccall(mxSetM,Void,(mxArray, Int,),prhs[id] ,size(args[id],1));
                ccall(mxSetN,Void,(mxArray, Int,),prhs[id] ,size(args[id],2));
                ccall(mxSetPr,Void,(mxArray,Ptr{Void}),prhs[id],pointer(args[id]));
            else
                #println("Dim diff 2");
                #println(ndims(args[id]));
            end
        elseif(argtype <: Number)
            #println("not tested");
            argTemp = convert(Float64, args[id]);
            #println(argTemp);
            prhs[id] = ccall(mxCreateDoubleScalar,mxArray,(Float64,), argTemp);
        end
        #
        #
    end
    #println("mexfunction");
    ccall(mexFunction,Void, (Int,Ptr{Uint8},Int,Ptr{Uint8}), nlhs, plhs, nrhs, prhs);
    #println("mexfunction end");
    #mxPush(plhs);
    #switch type output
    for id = 1:nlhs
        rettype = rettypes[id];
        M= ccall(mxGetM,Int,(mxArray,),plhs[id]);
        N = ccall(mxGetN,Int,(mxArray,),plhs[id]);
        #
        if(rettype == UTF8String)    
            buflen = M*N+1;
            #charTab = Array(Uint8,buflen);
            ret = Array(Uint8,buflen);			
            statut = ccall(mxGetString,Int,(mxArray,Ptr{Uint8},Int),plhs[id],ret,buflen);
            ret  = UTF8String(ret);
            push!(rets,ret);
        elseif(rettype <: Array)   
            #println(rettype);
            curType =  eltype(rettype);
            #println(curType);
            #println(plhs[id]);
            #println(curType);
            ret = ccall(mxGetPr, Ptr{Float64}, (mxArray,), plhs[id]);
            println(ret);
            ret = convert(Ptr{Float64},ret);
            #println(M);
            #println(N);
            #println(ret);
            ret = pointer_to_array(ret,M*N);
            ret = reshape(ret,M,N);
            push!(rets,ret);
        elseif(rettype <: Number)
            #println("not tested");
            #return is always a double
            ret = ccall(mxGetScalar, Float64, (mxArray,), plhs[id]);
            ret = convert(rettype, ret);
            push!(rets,ret);
        end
    end
end
#
#
function mxCall(method::String, args...)
    (nrhs, prhs) = convInput(args);
    #
    nlhs = 10; #length(rettypes);
    plhs = Array(mxArray,nlhs);
    #
    if( haskey(enumMxFunc,method))
        mexFile = enumMxFunc[method];
    else
        mexFile = method;
    end
    libmxfile = dlopen(mexFile);
    mexFunction = dlsym(libmxfile, :mexFunction);
    ccall(mexFunction,Void, (Int,Ptr{Uint8},Int,Ptr{Uint8}), nlhs, plhs, nrhs, prhs);
    #
    return plhs;
    #
end
#
#
#
function convInput(varargs...)
    #
    println("ConvInput\n");
    args = varargs[1][1];
    argtypes=typeof(args);
    println(argtypes);
    nrhs = length(argtypes);
    println(nrhs);
    prhs = Array(mxArray,nrhs);
    for id = 1:nrhs
        argtype = argtypes[id];
        #
        #switch type input
        if(argtype == UTF8String)
            println("Deb String \n");
            prhs[id] = ccall(mxCreateString,mxArray, (Ptr{Uint8},),args[id]);
            println("Fin String \n");
        elseif (argtype <: Array)
            if( ndims(args[id])==2 )
                println("Start Array\n");
                #see example arrayFillSetData.c
                prhs[id] = ccall(mxCreateNumericMatrix,mxArray, (Int, Int, Int, Int),0, 0, enumType[ eltype(args[id])],0) ;
                #println("num type");
                #println(enumType[ eltype(args[id])]);
                ccall(mxSetM,Void,(mxArray, Int,),prhs[id] ,size(args[id],1));
                ccall(mxSetN,Void,(mxArray, Int,),prhs[id] ,size(args[id],2));
                temp = mxAlloc(Int64,size(args[id],1),size(args[id],2));
                println("Malloc done\n");
                println(prod(size(args[id])));
                println(size(args[id]));
                for i=1:prod(size(args[id]))
                    temp[i] = args[id][i];
                end
                #
                ccall(mxSetPr,Void,(mxArray,Ptr{Void}),prhs[id],pointer(temp));
            else
                #println("Dim diff 2");
                #println(ndims(args[id]));
            end
        elseif(argtype <: Number)
            #println("not tested");
            argTemp = convert(Float64, args[id]);
            #println(argTemp);
            prhs[id] = ccall(mxCreateDoubleScalar,mxArray,(Float64,), argTemp);
        end
        #
        #
    end
    return (nrhs, prhs);
    #
end
#
#
function convOutput(output::mxArray)
    #
    #
    #
end



mxInit();



end # module
