-module(nodeselector).
-include("definition.hrl").
-export([main/1]).

main(V)->
    start_node(?HOST2,?PORT2,3),
    start_node(?HOST3,?PORT3,5),
    start_central_node(?HOST1,?PORT1,V).

start_central_node(HOST,PORT,V)->
    {ok,Fd}=file:open("log",[write,read,binary]),
    {ok,Sock}=gen_udp:open(PORT,[{ip,HOST},{port,PORT},binary,{active,true}]),
    loopc(Sock,V,0,Fd),
    ok.


loopc(Sock,_,100,Fd)->
    receive
        {_,_,Host,Port,<<"Ack",H,M,S>>}-> 
            io:format(Fd,"Ack from host:~p port:~p~n at~p:~p:~p",[Host,Port,H,M,S]);
        _-> gen_udp:close(Sock),
            file:close(Fd) 
    after 1000 -> gen_udp:close(Sock),
            file:close(Fd) end;
loopc(Sock,V,C,Fd)->
    case rand:uniform(2) of
        1 -> gen_udp:send(Sock,?HOST2,?PORT2,<<V>>),
            loopc(Sock,V+1,C+1,Fd);
        2 -> gen_udp:send(Sock,?HOST3,?PORT3,<<V>>),
            loopc(Sock,V+1,C+1,Fd) end.


start_node(H,P,V)->
    {ok,Sock}=gen_udp:open(P,[{ip,H},{port,P},binary,{active,true}]),
    receive
        {_,_,Host,Port,<<Message>>} when Message rem V ==0->
            {H,M,S}= time(),
            gen_udp:send(Sock,Host,Port,<<"Ack",H,M,S>>);
        _-> ok
    after 10000-> gen_udp:close(Sock) end.



