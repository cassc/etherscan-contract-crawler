// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rechild
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@#######Qgg88$0RDDggg88gD$g8QB#########################    //
//    @@@@@@@@@@@@@@@@@@@@###Bg8Qg3zVour**Lrr*r*xYrx]x;!===<r]}wK9QB############@@####    //
//    @@@@@@@@@@@@@@@@##B$ZbPhoXPsrrvL<!==v!!=!>xv^(v!_-.''..!,,:=}rvccb8Q######@@@@@#    //
//    @@@@@@@@@@@###QQgbWKmzVVVkKl>^*/!:!=r!::=rx^rr!.''`````,"`'-)*,_=!vxuhd$B#@@@@@@    //
//    @@@@@@@@#BQQQ$$D33eycl}luyev;~^/:::^^:":^/*vr!..'```` `-"  `!x_ !.,=:^x1sbg#@@@@    //
//    @@@###BB#B$8gD0h3yVyul}luyj\^*)\!=^v=::~)rri~----.`````__  `-(- ,-':-:*/lokM#@@@    //
//    @##BBQBQ#B8g$8bELIEveXXsK3jxvxl(^r})!~^/r*l/""::::",,:=^:_!::r: -~.:__^*}z}ud#@@    //
//    ##BBQQQQBBQ8$KzVyXjjhKPWMbse5HwiLlx<*)vv(i/!=~;^*r/vvxxv!~>~~*\__r__,_~*LwLxyD#@    //
//    #B#BQQQQQBQQ9VVuXkwkjIeKWbsM0R3Pezr]LixvLi!!~>*rvx}lu1}}~*>=!^r;,*~_:!=^xVLxL3#@    //
//    BB#BQQQQ8QQ$hyeO9RR0QBBBCoexistZMVcwuxxYx=__,=*vlIbRgQQ5odZmccir~*/"!~~r(llxxj8#    //
//    BBBQQBQQ88gMk5$QB800Q8##6Gy3DbEOdxO3LLx\~---"~rVGZKK90#v)b\egD3}v*\"!~~Lx1ci]IRB    //
//    BBBQQBQQ8gdeHD9QQg9Z008Q0ILcPMRdejG}y}vr-`'_!~(uIec}mZ3YKx!xsmekx^*"!=>u}ccL}KDB    //
//    BBQQQQQQ8D3mbdO$gD6dbO6R3yoKKPZMxzLMm}(!``'_:!>)]uVVckYV]tyB]vL\r^>:~~*u}wVL}GRQ    //
//    BQQQQQQQgR3P8WRROdbZMH3mmwjXyjkkvv3ZKL*.```-__"!>*(xxr/rr*****r==<>:~>^xLVc}1b$Q    //
//    #QQQQBBB06G60MObM3eXzkwywllVykVV*1PM3(:`  `.``.-,"::::!:::":!!=::;<~<*]rxll}ld8B    //
//    #BQQQBQ#gOd$6653mowcl}YLuLYuwy1u(oKHI~_'  `'`````.------.'._,::::~>**r}*\}}l}b8B    //
//    #BQQBBB#QRbDDEMsszVlYix]1}LVVlu})X3Hl~_'  ```    `` `-..``',,!::=~;**x}rrLiYLMQ#    //
//    ##QQ#QQ#BDG880PKewV1YLIilVuul1c}vw3hv^,'  ```        ``''.-::=!^=*^*)L}(*xxiY3Q#    //
//    ##QQBBQBQObBQRMMKjyu}}}love}uaywY}3l1r:'  ```         ``'-,!!!^>;*rrx}}lr/v]Yh8#    //
//    ##QBB##BgG08gg06MKIy1llVhVlcOlors/y}l):.` `''` ````  ```._"~~~<;*)v\YluuxvxL}X8#    //
//    ##QBBB#@0KOBBQ80OMPXkyyhKyVwh3GW5cxy}*:-` ``.``._--.'```-_:~;*^rvxxLulVulLLllj8#    //
//    #BQB###@O3bQQQ8$RdMPmeKHswzomGMZZ3*}L^".```'.```____--.-_"==*^/vxxlVVuwlul}uczQ#    //
//    #BQ####@dGO$QQ88D6d*Aminta_zI3ZOOWx)l)=_--_,_--'.-,",-___:!^>)))*wVlyVyuucuVVz8#    //
//    #BQ###@@$M$OQQ880ROZWGHKo*PaizPMbMV/jwLr^^~~=!_.''-,,,:_,!=;>^*^rOk}cyVuucywKKR#    //
//    #BQ##[email protected]@#MBd$Q8g0R6dMG3hozkkjoIXXoYx1Yx)^!"_-'```'.-_,"_::==!=>>h8Wolw1l1VykEEd#    //
//    #BQB#B#@@B986BQg0E9dMG3oozkkkzzyVlx(/*^r^!_-.```'..--,",::!=:!<LBBMZuyl1VVVKQ8O#    //
//    ##QB#B#@@@08Q8BQ0DE6bM3kIjzjoXIIjzj}x^<v(*<>~"_-___,_,:":!<~!~rO##MZkklVwVk9BQ0#    //
//    ##QB#[email protected]@@@#[email protected]#g0$DObGhXoh3Z9$$RMKcX1]vxxv/((/)r*^~!":::!^**xlH#BO3sjuwejK8#gQ#    //
//    ##BQB#@@@@#@B5#@Bg$8D6MPIIKb88g8Q85POEObdM3IwYxxxr>;~!!!~<^(lEOh08O3soyP0WPQQ8##    //
//    @#[email protected]@@@#@@@[email protected]@B888DdMKHHHZ6dMPjuuL)rrr*<;;^^:-.-_":!~^*rV8d8eObZWKsh8#$Mg8#@@    //
//    @#[email protected]@@#@@@@[email protected]@@#QQgDbZMMMMMZZM3kV1x\rrr*^~:,--___"!~*r/kQQ8MPMddOPKGB#Bd6##@@    //
//    @#Q#@#@@#@@#@[email protected]@#BQQ$RROdZMMMPKjwuuYxvx\*^~=!::::!!~*)xcM888$Md8QDOHPQ##RR#@@@    //
//    @#Q#@###@#@@@[email protected]@##BQQQ80RdMHejlylYLvr***^>~!!!!!!=~rx}V3RQ##BQD#Qg#BP$##DE#@@@    //
//    @[email protected]@@###@@@[email protected]#@@#BQQBBBQgRZPeXklLxvv*;=!::""":!!~*lZ$QB#######68#@@@DMQB8$#@@@    //
//    @[email protected]@@@[email protected]@@@[email protected]@#######@@@#Q06Whwc}Liv*;!!:::::=<*}d8QQQQQQ8g8QQ9#@@@@#ddQBQ#@@@    //
//    @B#@@@@[email protected]@@#@#[email protected]@@@@@@@@@@@@#B0b5mzVLx\)*^;~^*rvm8######BB######0######86RBQ#@@@    //
//    QQ#@@@@[email protected]@@B##@@@@@@@@@@@@@#@@@#QDMKhjkwu}}YVWD#################0######Q$ZQQ#@@@    //
//    [email protected]##@@@#@@@[email protected]@@@@@@@#@@@@@#@@@@@@@#########@@@@@@@#############E#######QdQQ####    //
//    ################################################################amintaonline.com    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract RECHILD is ERC721Creator {
    constructor() ERC721Creator("Rechild", "RECHILD") {}
}