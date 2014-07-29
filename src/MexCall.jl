module MexCall

export mxInit, mxAlloc, mxDestroy, mxFreeArray, mxCall, mxAddMexFile, mxGetPointer, mxSetPointer, enumMxFunc, convInput, getMxPenv
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
function mxPush(element::Ptr)
    push!(mxPenv,element);
end
#
function mxPush(element::Array)
    push!(mxPenv,element);
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

function mxSetPointer(anMxArray,aPtr)
   ccall(mxSetPr,Void,(mxArray,Ptr{Void}),anMxArray,aPtr);
end

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
                mxSetPointer(prhs[id],pointer(args[id]))
                # ccall(mxSetPr,Void,(mxArray,Ptr{Void}),prhs[id],pointer(args[id]));
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
            ret=mxGetPointer(plhs[id])
            #ret = ccall(mxGetPr, Ptr{Float64}, (mxArray,), plhs[id]);
            #println(ret);
            #ret = convert(Ptr{Float64},ret);
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
function mxCall(method::String, nlhs, args...)
    println("mxCall");
    #println(args);
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
    println("Will call ccall now \n");
    println(nrhs);

    ccall(mexFunction,Void, (Int,Ptr{Uint8},Int,Ptr{Uint8}), nlhs, plhs, nrhs, prhs);
    println("End of ccall \n");
    
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
function extractOutput(nlhs, output::Array{mxArray})
    #
    println("extractOutput\n");
    println(output);
    ret = Array(Any,nlhs);
     for i = 1:nlhs
         println(i);
         if( (output[i]!= C_NULL) && (!ccall(mxIsEmpty, Bool, (mxArray,), output[i]))  )
             println("start for loop");
             println(output[i]);
             M= ccall(mxGetM,Int,(mxArray,), output[i]);
             N = ccall(mxGetN,Int,(mxArray,), output[i]);
             #println(M);
             #println(N);
             if( ccall(mxIsNumeric, Bool, (mxArray,), output[i]))  # numeric
                 curType = Any;
                 if( ccall(mxIsDouble, Bool, (mxArray,), output[i]))  # double
                     println("Double output");
                     curpointer = ccall(mxGetPr, Ptr{Float64}, (mxArray,), output[i])
                 elseif( ccall(mxIsSingle, Bool, (mxArray,), output[i]))  # single
                     println("Single output");
                     curpointer = ccall(mxGetPr, Ptr{Float32}, (mxArray,), output[i])
                 elseif( ccall(mxIsInt8, Bool, (mxArray,), output[i]))  # Int8
                     println("Int8 output");
                     curpointer = ccall(mxGetPr, Ptr{Int8}, (mxArray,), output[i])
                 elseif( ccall(mxIsInt16, Bool, (mxArray,), output[i]))  # Int16
                     println("Int16 output");
                     curpointer = ccall(mxGetPr, Ptr{Int16}, (mxArray,), output[i])
                 elseif( ccall(mxIsInt32, Bool, (mxArray,), output[i]))  # Int32
                     println("Int32 output");
                     curpointer = ccall(mxGetPr, Ptr{Int32}, (mxArray,), output[i])
                 elseif( ccall(mxIsInt64, Bool, (mxArray,), output[i]))  # Int64
                     println("Int64 output");
                     curpointer = ccall(mxGetPr, Ptr{Int64}, (mxArray,), output[i])
                 elseif( ccall(mxIsUint8, Bool, (mxArray,), output[i]))  # Uint8
                     println("Uint8 output");
                     curpointer = ccall(mxGetPr, Ptr{Uint8}, (mxArray,), output[i])
                 elseif( ccall(mxIsUint16, Bool, (mxArray,), output[i]))  # Uint16
                     println("Uint16 output");
                     curpointer = ccall(mxGetPr, Ptr{Uint16}, (mxArray,), output[i])
                 elseif( ccall(mxIsUint32, Bool, (mxArray,), output[i]))  # Uint32
                     println("Uint32 output");
                     curpointer = ccall(mxGetPr, Ptr{Uint32}, (mxArray,), output[i])
                 elseif( ccall(mxIsUint64, Bool, (mxArray,), output[i]))  # Uint64
                     println("Uint64 output");
                     curpointer = ccall(mxGetPr, Ptr{Uint64}, (mxArray,), output[i])
                 end
                 curpointer = pointer_to_array(curpointer, M*N);
                 ret[i] = reshape(curpointer, M, N);
                 println(ret[i]);
             elseif ( ccall(mxIsChar, Bool, (mxArray,), output[i]))  # string
                 buflen = M*N+1;
                 ret[i] = Array(Uint8,buflen);			
                 statut = ccall(mxGetString,Int,(mxArray,Ptr{Uint8},Int),output[i],ret[i],buflen);
                 ret[i]  = UTF8String(ret[i]);
             end
             
             println("end for loop");
         end

         return ret;
     end

#size(output,1)>0)
# println(size(output,1));
# i=1;
# while( output[i]!= C_NULL && ccall(mxIsEmpty, Bool, (mxArray,), output[i] ))
#     println(i);
#     println(output[i])
#     println("\n");
#     i+=1;
# end 
#
    
    #
end



#mxInit();



end # module
