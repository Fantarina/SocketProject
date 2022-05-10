-module(nodeselector).
-include("definition.hrl").
-export([main/1]).
%%Log onto a file to see the break step by step
%%Will use wireshark later
main(V)->
    start_node(?HOST2,?PORT2,3),
    start_node(?HOST3,?PORT3,5),
    start_central_node(?HOST1,?PORT1,V).

start_central_node(HOST,PORT,V)->
    {ok,Fd}=file:open("log",[write,binary]),
    io:fwrite(Fd,"~p",[<<"Halala1~n">>]),
    {ok,Sock}=gen_udp:open(PORT,[{ip,HOST},{port,PORT},binary,{active,true}]),
    loopc(Sock,V,0,Fd),
    ok.


loopc(Sock,_,100,Fd)->
    receive
        {_,_,Host,Port,<<"Ack",H,M,S>>}->
            io:fwrite(Fd,"~p",[<<"Halala2~n">>]),
            io:fwrite(Fd,"Ack from host:~p port:~p~n at~p:~p:~p",[Host,Port,H,M,S])

    after 1000 -> gen_udp:close(Sock),
            io:fwrite(Fd,"~p",[<<"Halala3~n">>]),
            file:close(Fd) end;
loopc(Sock,V,C,Fd)->
    io:fwrite(Fd,"~p",[<<"Halala4~n">>]),
    case rand:uniform(2) of
        1 -> gen_udp:send(Sock,?HOST2,?PORT2,<<V>>),
            io:fwrite(Fd,"~p",[<<"Halala5~n">>]),
            loopc(Sock,V+1,C+1,Fd);
        2 -> gen_udp:send(Sock,?HOST3,?PORT3,<<V>>),
            io:fwrite(Fd,"~p",[<<"Halala6~n">>]),
            loopc(Sock,V+1,C+1,Fd) end.


start_node(H,P,V)->
    {ok,Sock}=gen_udp:open(P,[{ip,H},{port,P},binary,{active,true}]),
    loops(Sock,V).


loops(Sock,V)->
    receive
        {_,_,Host,Port,<<Message>>} when Message rem V ==0->
            {H,M,S}= time(),
            gen_udp:send(Sock,Host,Port,<<"Ack",H,M,S>>),
            loops(Sock,V);
        _-> loops(Sock,V)
    after 10000-> gen_udp:close(Sock) end.



