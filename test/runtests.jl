#
using MexCall
using Base.Test
#
#
#method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64";
#method="C:/Users/user/Documents/Julia/writekhoros_info.mexw64"
#mxAddMexFile(method,0)
#@mxAddMexFileV2(:($method),0)
#
@mxAddMexFile("C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64",-1)
#@mxAddMexFile("C:/Users/user/Documents/Julia/writekhoros_info.mexw64",0)
#enumMxFunc
#
@mxAddMexFile("C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/readkhoros_info.mexw64",2)
#
#
readkhoros_info("C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/MatlabKhoros_out_test.1")




writekhoros_info("tetetetete", [10.0 10 10 10 10] ,  "uint8")
#
#

writekhoros_info("tetetetete", [10.0 10 10 10 10] ,  "uint8";nlhs=2)




#readkhoros_info("C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/MatlabKhoros_out_test.1";nlhs=1)



#### dev test ####

#
#
#
function exampleA()
    #
    mxInit();
    method = "C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/yprime.mexw64";
    args = (1,[1.0 2 3 4]);
    rets = mxCall(method, 1, args);
    println("result :");
    println(rets);
    #
    mxDestroy();
end
#
#
#
function exampleB()
#
    mxInit();
    #method = "exemples/readkhoros_info.mexw64";
    method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/readkhoros_info.mexw64";
    #rettypes = (Array{Float64,2}, UTF8String);
    #argtypes = (UTF8String,);
    #rets = Any[];
    #args = ["exemples/MatlabKhoros_out_test.1"];
    #mxCall(method,rettypes,argtypes, rets, args)
    #rets
    #                if wrong path Julia crash
    args = ("C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/MatlabKhoros_out_test.1",);
    #mxCall(method,rettypes,argtypes, rets, args)
    #rets
    rets = mxCall(method,2,args);
    println("result :");
    println(rets);
    mxDestroy();
    #
    #
end
#
#
function exampleC()
    #   
    mxInit();
    #
    #using MexCall;
    #method = "exemples/writekhoros_info.mexw64";
    method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64";
    #rettypes = ();
    #argtypes = (UTF8String, Array{Int}, UTF8String);
    #rets = Any[];
    #
    #a = mxAlloc(Int64,1,5)
    #for i=1:5
    #    a[i]=10;
    #end
    #args = ["aaazzz", 0 ,  "uint8"];
    #args[2] = a
    #
    #mxCall(method,rettypes,argtypes, rets, args);
    #mxFreeArray(a);
    args = ("aaazzz", [10.0 10 10 10 10] ,  "uint8");
    rets = mxCall(method,0, args);
    println("result :");
    println(rets);
    mxDestroy();
    #
end
#
#
#
exampleA()
#
exampleB()
#
exampleC()
#
#





#
#method="C:\\Users\\user\\AppData\\Local\\Temp\\user\\cuda_cuda.mexw64"
function cuda_cuda(retTypes,varargs...)
    method="C:/Users/user/AppData/Local/Temp/user/cuda_cuda.mexw64"
    #
    #    rettypes=(Float64,)
    #    argtypes=typeof(varargs); # (UTF8String,Int64)
    #        args= Array(Any,1);
    #       args[1]="put";
    #       args[2]=refnum;
    #   rets= Array(Any,5);
    # libmxfile = dlopen(method)
    println(varargs)
#
    rets=mxCall(method,retTypes,varargs)
    return rets
end
# cuda_cuda('put',single(in));
#
#
#
#
function writekhoros_info(varargs...)
    #method="C:/Users/user/Documents/Julia/writekhoros_info.mexw64"
    #cd("C:/Users/user/Documents/Julia/")
    method="C:/cygwin64/home/Simon/work/juliaWork/juliaMex/exemples/writekhoros_info.mexw64";
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
    #
    return rets
end
#
#
#
#
#





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



function ter(args...;test=1)
    return (test,args[1])
end
methods(ter)

