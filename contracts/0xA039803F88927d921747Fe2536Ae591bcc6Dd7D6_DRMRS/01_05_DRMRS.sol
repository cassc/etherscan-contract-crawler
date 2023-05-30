// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAMERS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    @@@T|[email protected]@@w  |l*'"   ,;w  ;[email protected]@@@@@Nw   '*%%@@@@@@@@@@@@g/%%@@@@@@,"[email protected]@@@  ]@@@@    //
//    M|lll%@@@M*  ;g ]" "*"  '"'|:=wwggggpg/  '|j%%@@@@@@@@@@@g*%%@@@@@,l%[email protected]@@g "[email protected]@    //
//    ll|lM*"  ,r ,`- * ** gN*       ''*%%%@@@w   ''j%@@@@@@@@@@@p*%%%@@@g|%[email protected]@@N  %@    //
//    l'`  gg ,P """ [email protected]@N*`    ''|[email protected]@@Npg  "%%@ @@Npg,"%@@@@@@@@@@N l|M%%@@|[email protected]@@@  ]    //
//     ,g  `" * [email protected]@N"`   `']P  ''"'"**%%k g,g,"%@@@@@g/%@@@@@@@@@@ ,, `;",|[email protected]@      //
//     `" *" & ggpm"  ,,, ]C;" =  '"|**Mmg, "[email protected]@@@w"@@@@@g"%@@@@%MMT '%@@@@@@Lj$$|#@K     //
//    @@K @gwg,,#' ,gg  C C @ P| K"w"~| \ \"*N,*@@@@w]@@@@@ ***T|!'   ]%@@@@@@|l|[email protected]@@L    //
//    *[email protected] *"[email protected]@* ,,; , #C'p%]g"w]MQ*[email protected]@$$**^]r"%w*@@@g'%%MT ]@@ggg,;, /j%@@@@ML [email protected]@@@F    //
//     *M [email protected]@F ;;g,  @ %@c'\*-*%Nw,"**[email protected]@[;] "%,%@@r;''   |%%@@@M'/@|j$$MTL @@@@@@|    //
//     ][email protected]" =www/][email protected]/**[email protected]@@p!%@@,`]$**MNw-"\  ]w]@L]@@pg,,'|TT",@@@L|l||`;@@@M$ML]    //
//     |,[email protected]   w,/ ]@[email protected]@@ |%@@N '%@@@gwg%@@@@Q~    } '%%@@@F  ,[email protected]@@@@F ' ,@@@@@T||[email protected]    //
//     [email protected]@`   "r- |]@@g|[email protected]@@p'|@@@@@@@[email protected][email protected]@@@@@|||   , '*TT'' %@@@@@@M|>[email protected]@@@@@@F`@@@    //
//    @@@L  ` "'" |]@@@p|[email protected]@@[email protected]@@@@@@@@g%W||   '%@@gpw @'j%MMT",@|j%@@@@ML,@@@@    //
//    @@F 4 "" *^ |]@@@@,,,*[email protected]@@@@@@@@@@@$N&@L||   $MMT';@@ '|' ,@@@L lMMT',@@@@@|    //
//    T!  g&    " |]@@@@@@@@@@@@@@@@@@@@@@@%&&@[email protected]|    }|',@@@@L  [email protected]@@@@g  ' [email protected]@@@@@Lj    //
//    L  @lj    x |@@%[email protected]@@@@@@@@@@@@@@M*%%gg$L     |#MMMMM"|*MMMMMT*|#%@@@@@%M'[email protected]    //
//    g '    ,lww ][email protected]@@@@[email protected]@[email protected]@@@@[email protected]@@@@N=][email protected]@@@   ,;  ||||| [email protected] ||||| [email protected]|||TTT!\@@@    //
//    @@@ ] "`~`-l *@@@@@@@@@@@@[email protected]@@@[email protected]@.*%@@@@  g,,@@ llF;@@@g;lL,[email protected]@@@@,|||`[email protected]@@@    //
//    @@@@ L ^ ^{"+ [email protected]@@@@@@@@@@@@@@@L    [email protected]@@L"|T**M**L#MMMMT|!l|%%@@@%MF [email protected]@@@@T    //
//    @[email protected]@L"  `u>+\@@@@@@@@@@@@@@@@@@@@@@gL |[email protected]@@@,||||L @g ||||L,@@L'|l||! [email protected]@@@@M|j    //
//    L)@@@ \ 2^~)@@@@@@@[email protected]@@@@@@@@@@@@@i '[email protected]@@@@ $l'[email protected]@@@glM\[email protected]@@@L ' ;@@@@@@@M|@@    //
//    ;]@@@@ -  [email protected]@@@@@@@@@[email protected]@@@@@@@@@L ]@@@@M*||{|''||'';@'"'''|*[email protected]@@@@@%[email protected]@@    //
//    @@[email protected]@@@ *[email protected]@@@@@@@@@@@@@@gggg]@@@@@@@@|jMM*}  / jL|||',@@@L ||';@@|||||||!,@@@@M    //
//    @`]@@@@@ ]@@@@@@@ggggggg]@@@$$$$%@@@@@@@@@@gp,@@wl|[email protected]@@@@@,,[email protected]@@@L||||')@@@@@Ml    //
//    N *[email protected]@@@, [email protected]@@@]@@@@@@@@@[email protected]@@@[email protected]@[email protected]@N,> !"';@L|||||||%%@@@@@@@w| [email protected]@@@@@[email protected]    //
//     #[email protected]@g [email protected]@@@[email protected]@@@@[email protected]@@@@@M*^,[email protected]@@@@@  '|ll&$$$$MMT';[email protected]@@@@@@M|@@@    //
//     @@@@@@@@@@@,*%[email protected]@@@@@@@[email protected]@@@@@@@@@ ,  '"""****$Nwg;,,'||,[email protected]@@@@@@@MM|[email protected]@@@    //
//    , %@@@@@@@@@@@,"[email protected]@[email protected]@@@@@@@@F***$|%T%MM%%@@@%%MMMMT*[email protected]@L||||TMMMMT|[email protected]@@@@$    //
//    @K \,,; %@@@@@@@,"[email protected]@@@@@@@@@@@@@@@;  '*%llWlllllTT*";[email protected]@@@@L||||||||;[email protected]@@@@$$$    //
//    MM "%@@@`@@@@@@@@@,"[email protected]@@["M%%@@@@@[email protected]@@@@@@@@@@@@@g||||,[email protected]@@@@@$$$M|    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract DRMRS is ERC721Creator {
    constructor() ERC721Creator("DREAMERS", "DRMRS") {}
}