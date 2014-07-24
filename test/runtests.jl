using MexCall
using Base.Test
#
#

#
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
