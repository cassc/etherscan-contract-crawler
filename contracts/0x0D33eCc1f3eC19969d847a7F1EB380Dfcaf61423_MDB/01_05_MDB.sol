// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIDABI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWOc:::::c0MMMMMMMM0l:c:::c0MMMNd:c:cOMMMWx::::::::clokXWMMMMMMMMMMMM0l:c:::cOMMMMMMMMM0l:c:::::ccox0NMMMMMMMWkc:::xNMM    //
//    MMWl       :NMMMMMMWl       dMMMK,    lWMMN:            .c0WMMMMMMMMMWc       :NMMMMMMMMd            .'oKMMMMMWc    ;XMM    //
//    MMWl       .OMMMMMM0'       dMMMK,    lWMMN:    .'''..    .xNWMMMMMMM0'       .OMMMMMMMMd     .'''.     'OMMMMWc    ;XMM    //
//    MMWl        lWMMMMWd        dMMMK,    lWMMN:    ;XWNN0:    'o0MMMMMMMd         oWMMMMMMMd     lNWNKl.    ;XMMMWc    ;XMM    //
//    MMWl        '0MMMMX;        dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMMMX:    .    ;XMMMMMMMd     oWMMMX;    .OMMMWc    ;XMM    //
//    MMWl         oWMMMx.        dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMMMO.   'o'   .kMMMMMMMd     oMMMMK,    ,KMMMWc    ;XMM    //
//    MMWl         ,KMMN:         dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMMWl    :K:    lWMMMMMMd     :OOOd,    .xWMMMWc    ;XMM    //
//    MMWl    ';   .xMMO.  .;.    dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMMK,    oWd    '0MMMMMMd             .:OWMMMMWc    ;XMM    //
//    MMWl    ;x'   :XWl   ,d'    dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMMx.   .OMO.   .xMMMMMMd              ,xNMMMMWc    ;XMM    //
//    MMWl    ;Kl   .k0'   oO.    dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMNc    ;XMX;    :NMMMMMd     :OOOx:.    :XMMMWc    ;XMM    //
//    MMWl    ,K0'   co.  .OO.    dMMMK,    lWMMN:    :NMMMMO.   .;kMMMM0'    .,,,.    .OMMMMMd     oMMMMNl     oWMMWc    ;XMM    //
//    MMWl    ;XWo   ..   lWO.    dMMMK,    lWMMN:    :NMMMMO.   .;kMMMMd               oWMMMMd     oMMMMMx.    :NMMWc    ;XMM    //
//    MMWl    ;XM0'      .OMO.    dMMMK,    lWMMN:    :NMMMMk.   .:kMMMX;    .ccccc.    ;XMMMMd     oMMMMNl     cNMMWc    ;XMM    //
//    MMWl    ;XMWo      cNMO.    dMMMK,    lWMMN:    ,kOOko'    ;kXMMMk.    dWMMMMd    .kMMMMd     :OOkd;     .kMMMWc    ;XMM    //
//    MMWl    ;XMMK,    .kMMO.    dMMMK,    lWMMN:              :KMMMMWl    .OMMMMMO.    lWMMMd               .xWMMMWc    ;XMM    //
//    MMWl    ;XMMWd.   cNMMO'   .xMMMK;    oWMMN:          .,cONMMMMMK,    cNMMMMMN:    ,KMMMx.          ..;dKMMMMMWc    :XMM    //
//    MMMXkkkk0WMMMNOkkOXMMMN0kkkOXMMMW0kkkkXMMMWKkkkkkkkkOOKNMMMMMMMMNOkkkkXMMMMMMMXkkkkONMMMXOkkkkkkkkkO0XWMMMMMMMMKkkkkKWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MDB is ERC721Creator {
    constructor() ERC721Creator("MIDABI", "MDB") {}
}