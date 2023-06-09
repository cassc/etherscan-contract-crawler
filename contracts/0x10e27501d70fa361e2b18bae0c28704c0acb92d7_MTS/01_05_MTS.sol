// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mike Shupp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]$||"*$l]g#[email protected][email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]$$$|l   '`llL"l%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@|| l|T '|[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@[email protected]@@MMT|'"     `"*| |j&[email protected]@@@@@@@@@@@@[email protected]@@@@@    //
//                                                                                        //
//    @@@@@@@@@@[email protected]@@@@@@@@@@[email protected]$$$lLL||||            ||[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@[email protected]@@@@@@@@@@@@@@@[email protected]@@@@$lLlL||             '|'%@@@@@@@@@@@@@@@@@@#@@@@@    //
//                                                                                        //
//    @@@@@@[email protected]@[email protected]@@@@@@@@@@[email protected]@@@@@@[email protected]|L              %@@@@@@@@@@@@@@@@@@NNMM$    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$&$$$$$WL|              ]@@NNMM*[email protected]@@@]@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@$$$T||||| `                [email protected]@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@gL| |||L|             ]@@@@@@@@@NNNMM$$$$]@@@    //
//                                                                                        //
//    @@@@@[email protected]@@@@@[email protected]@[email protected]@@@@@@@[email protected][email protected]@@@gLll$W|LL           $][email protected]@@@@@@@@@@@@[email protected]@    //
//                                                                                        //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@gg,       [email protected]@@@@[email protected]@@@@@@@]@@    //
//                                                                                        //
//    @@@@[email protected]@@@@@@@@@@@[email protected][email protected]@@@@@@@@@@@@@@F'']@@@@@@@@L    jMM&&IJP**"""""` -- |||    //
//                                                                                        //
//    @[email protected]@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@|  l%@@@@@@@@,             ,,,,[email protected]@@@    //
//                                                                                        //
//    @@@@@@@@[email protected]@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@L   '%@@@$I '"   ,@@@@@@@@@@BNMMMMMMMMM$    //
//                                                                                        //
//    @@$Q$%@MT|*"*""' -`   @@@@@@@@@@[email protected]@@@@@T       "*W'      '"'''''"`` ||||||||lll$    //
//                                                                                        //
//    $$lT|||,,,,,[email protected]@@@@@@@@@@@[email protected]@@@gg,                               ||||ll$    //
//                                                                                        //
//    @@@@@@@@@@NMMMM***''''[email protected]@@@@@@[email protected]@@@@@@@@@L,, @@g              ,,,,.=+~~***"$$$$    //
//                                                                                        //
//    $$$$$lll||||||||      @@@@@@@@@@@@@@@@@@@g "" *%@@L      ,,,+=>[email protected]@@@    //
//                                                                                        //
//    @$$$$lll||||||||  ,,,,[email protected]@@@@@@@@@@@@@@@@[email protected]@     |T"Q     ilLllll||||llll$$$$$$$$    //
//                                                                                        //
//    @@NNMM**$$$l,[email protected][email protected]@@@@@@@@@@@@@@@L"jT,   ,y,| T   l||||||||||[email protected]    //
//                                                                                        //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@     l||||||||||llll$$$&$$$$$    //
//                                                                                        //
//    @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@$$$M|    '[email protected]@L   [email protected]@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@g,   $$   $MMMMM%@"""]@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@MMTMLlL||'         |$    @@@@[email protected]@@@@@@@    //
//                                                                                        //
//    @@@@@@@@%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@|L  '''  ,g      ,,$    [email protected]@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@gL,    ,@@@@@@@@@@@@F   ]@[email protected]@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ggL ]@@@@@@@@@@@@@@   [email protected]@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M|']@@@@@@@@@@@@@@@L ||[email protected]@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@W||l]@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]|[email protected]@@@@@@@@@@@@@@@@g|[email protected]@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@l|||||[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@||[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MTS is ERC721Creator {
    constructor() ERC721Creator("Mike Shupp", "MTS") {}
}