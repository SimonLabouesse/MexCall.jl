using MexCall
using Base.Test
#
function test2()
    mxInit();
    mxStringA = ccall(mxCreateString,Ptr{Void}, (Ptr{Uint8},),"test2");
    mxStringB = ccall(mxCreateString,Ptr{Void}, (Ptr{Uint8},),"BBBBB");
    nlhs = 2;
    plhs = Array(Ptr{Void},nlhs);
    plhs[1] = mxStringA;
    plhs[2] = mxStringB;
    pushEnv(plhs);
    push!(mxPenv,mxStringA);
    mxpenv;
    mxDestroy();
    mxPenv;
end
#
#
function test()
    mxString = ccall(mxCreateString,Ptr{Void}, (Ptr{Uint8},),"test2"); 
    M= ccall(mxGetM,Int,(Ptr{Void},),mxString);
    N = ccall(mxGetN,Int,(Ptr{Void},),mxString);
    buflen = M*N+1;    
    charTab = Array(Uint8,buflen);
    statut = ccall(mxGetString,Int,(Ptr{Void},Ptr{Uint8},Int),mxString,pointer(charTab),buflen);
    s  = UTF8String(charTab);
    println(s);
end
#
#

#method="C:\\Users\\user\\AppData\\Local\\Temp\\user\\cuda_cuda.mexw64"
function cuda_cuda(varargs...)
    method="C:/Users/user/AppData/Local/Temp/user/cuda_cuda.mexw64"

    rettypes=(Float64,)
    argtypes=typeof(varargs); # (UTF8String,Int64)
#        args= Array(Any,1);
 #       args[1]="put";
 #       args[2]=refnum;
    rets= Array(Any,5);
    # libmxfile = dlopen(method)
    println(varargs)

    mxCall(method,rettypes,argtypes,rets,varargs)
    return rets
end
# cuda_cuda('put',single(in));


function writekhoros_info(varargs...)
    method="C:/Users/user/Documents/Julia/writekhoros_info.mexw64"

    rettypes=(Float64,)
    argtypes=typeof(varargs); # (UTF8String,Int64)
#        args= Array(Any,1);
 #       args[1]="put";
 #       args[2]=refnum;
    rets= Array(Any,5);
    # libmxfile = dlopen(method)
    println(varargs)
    println(argtypes)

     mxCall(method,rettypes,argtypes,rets,varargs)
    return rets
end


writekhoros_info("hello monde",[10 10 10 20 20],"uint8")

cuda_cuda("cuda_memory");

ret=cuda_cuda("rr",[10 10],[10 10]);

a=rand(10,10)


# is mexErrMsgTxt supported???  Can it be supported?