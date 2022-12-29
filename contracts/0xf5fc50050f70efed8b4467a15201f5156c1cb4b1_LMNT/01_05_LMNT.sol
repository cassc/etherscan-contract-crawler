// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RoseJade || LMNT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0xxxxxxONMMMMMMMMMMMMMMMMNOxxxxxxxkKWMMMMMMMMMMMMXkxxxxxx0WMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMO.        ;KMMMMMMMMMMMK:       ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.         cNMMMMMMMMMNl        ,0MMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMO.         .dWMMMMMMMWk.        ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.          'OMMMMMMM0,         ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.           :XMMMMMNc          ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.           .oWMMMWd.          ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.            .kWMMO'           ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.   .lc       ;KMX:   cc.      ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.   .kK,       lKo   ,Kx.      ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.   .kWx.      ...  .xWk.      ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.   .kMNc           cNMk.      ,KMMMMMMMMMM    //
//    MMMMMMMMMMK,      .kMMMMMMMMMMMMMMMMk.   .kMM0'         ,0MMx.      ,0MMMMMMMMMM    //
//    MMMMMMMMMMK,      .oXXXXXXXXXXXXWMMMk.   .kMMWd.       .dWMMx.      ,0MMMMMMMMMM    //
//    MMMMMMMMMMK,       .............oNMMk.   .kMMMX:       cXMMMx.      ,0MMMMMMMMMM    //
//    MMMMMMMMMMXc....................lNMM0;...,OMMMM0;.....;0MMMMO,......cXMMMMMMMMMM    //
//    MMMMMMMMMMWNKKKKKKKKKKKKKKKKKKKKNMMMWXKKKXWMMMMWNKKKKKNWMMMMWXKKKKKKNWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKOOOOOOOKWMMMMMMMMMWX0O0XMMMWX0OOOOOOOOOOOOOOOOOOOOOOO0XMMMMMMMMMMM    //
//    MMMMMMMMMMMM0,       .oNMMMMMMMMXc. .oWMMXc                        .oWMMMMMMMMMM    //
//    MMMMMMMMMMMMO.         cXMMMMMMMX;   cNMMNd,''''''.        .''''''',xWMMMMMMMMMM    //
//    MMMMMMMMMMMMO.          ;KMMMMMMX;   cNMMMWWNNNNNWK;       cXNNNNNNWWMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.           ,OWMMMMX;   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.            .xWMMMX;   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.   ;:.       .oNMMX;   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xNd.        cXMX;   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMWk'        ;0X;   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMW0,        'c.   cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMMMK:             cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMMMMXl.           cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMMMMMNd.          cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMMMMMMWk'         cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.  .xMMMMMMMMW0,        cNMMMMMMMMMMMN:       oWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0,  .kMMMMMMMMMMKc.     .oWMMMMMMMMMMMNl.     .dWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKOO0NMMMMMMMMMMMN0OOOOO0XMMMMMMMMMMMMWX0OOOOO0NMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract LMNT is ERC721Creator {
    constructor() ERC721Creator("RoseJade || LMNT", "LMNT") {}
}