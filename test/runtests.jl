#
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


function ExampleA()
    mxInit();
    method = "C:/Users/Simon/Perso/projets/stage/IPHT/julia/myType/juliaMex/exemples/yprime.mexw64";
    rettypes = (Array{Float64,2},);
    argtypes = (Int,Array{Float64,2});
    rets = Any[];
    a = mxAlloc(Float64,1,4);
    for i=1:4
        a[i]= i;
    end
    args = [1, Any];
    args[2]=a;
    mxCall(method,rettypes,argtypes, rets, args)
    rets
    mxDestroy();
end


function ExampleB()

    mxInit();
    method = "exemples/readkhoros_info.mexw64";
    rettypes = (Array{Float64,2}, UTF8String);
    argtypes = (UTF8String,);
    rets = Any[];
    args = ["exemples/MatlabKhoros_out_test.1"];
    mxCall(method,rettypes,argtypes, rets, args)
    rets
    mxDestroy();
    #

end


function ExampleC()
    
    mxInit();
    #
    #using MexCall;
    #method = "exemples/writekhoros_info.mexw64";
    method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64";
    rettypes = ();
    argtypes = (UTF8String, Array{Int}, UTF8String);
    rets = Any[];
    #
    a = mxAlloc(Int64,1,5)
    for i=1:5
        a[i]=10;
    end
    args = ["aaazzz", 0 ,  "uint8"];
    args[2] = a
    #
    mxCall(method,rettypes,argtypes, rets, args);
    mxFreeArray(a);
    mxDestroy();

end


using MexCall
using Base.Test
#method="C:\\Users\\user\\AppData\\Local\\Temp\\user\\cuda_cuda.mexw64"
function cuda_cuda(retTypes,varargs...)
    method="C:/Users/user/AppData/Local/Temp/user/cuda_cuda.mexw64"

#    rettypes=(Float64,)
#    argtypes=typeof(varargs); # (UTF8String,Int64)
#        args= Array(Any,1);
 #       args[1]="put";
 #       args[2]=refnum;
 #   rets= Array(Any,5);
    # libmxfile = dlopen(method)
    println(varargs)

    rets=mxCall(method,retTypes,varargs)
    return rets
end
# cuda_cuda('put',single(in));

#

function writekhoros_info(varargs...)
    method="C:/Users/user/Documents/Julia/writekhoros_info.mexw64"
    cd("C:/Users/user/Documents/Julia/")
    #method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64";
    #
    rettypes=(Float64,);
    #
    argtypes=typeof(varargs); # (UTF8String,Int64)
    #        args= Array(Any,1);
    #       args[1]="put";
    #       args[2]=refnum;
    rets= Array(Any,5);
    # libmxfile = dlopen(method)
    #println(varargs)
    #println(argtypes)
    #
    # mxCall(method,rettypes,argtypes,rets,varargs)
    #
    mxCall(method,(),varargs)

    return rets
end


writekhoros_info("hello monde",[10.0 10 10 20 20],"uint8")

cuda_cuda((),"cuda_memory");

ret=cuda_cuda((Float64,),"rr",[100.0 100.0],[-1.0 -1.0],[1.0 1.0]);
ret2=cuda_cuda((Float64,),"times",ret[1],ret[1]);

myrr=cuda_cuda((Array{Float32},),"get",ret2[1]);

#a=rand(10,10)


# is mexErrMsgTxt supported???  Can it be supported?

function foo(outputs::Array{Any},input1)
    outputs[1]=15;
    outputs[2]="Hello World";
end
