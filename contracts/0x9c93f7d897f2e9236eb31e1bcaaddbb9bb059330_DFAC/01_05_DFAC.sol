// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dogface Comic Strip
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.   .;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.      lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;     .OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:     ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.    'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.    .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WWWMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWMMMMMMMMMMMMx.     .xMMMMMMMMWNNNNWWWWWWWWWWMMMMMMMWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNWWWWWWWWWW    //
//    :;;:dXWx:lxXWMMMMMMMWKxlkWXkx0NMMMMMMMMWXx:,oXNd:lONMMMMMMMMWd.     .kMMMMMMMKc..'',,,,,,,,,oXMMMMMNo.',;dNMMMMMMMMMWX0dcxNOclkXMMMMMMXl'.'',,,,,,,,,;    //
//        .ONc   'dXMMMMWO:.  ,KO. .;xNMMMMMXd.   '0X;  .cKMMMMMMMWx.     .kMMMMMMMO.             ,KMMMMMNl    .OMMMMMMMMXo'.  :Xd   ,kWMMMM0'                  //
//    .   'OWo.    cXMMMO.    ;XO.    lNMMMX:    .lXNo.   :XMMMMMMMx...   .kMMMMMMMO.    .''''.'''dNMMMMMMk.   .dWMMMMMMK:     lXd.   .xWMMM0'    .''.''''.'    //
//        .OMNk,   .dWMWl    ;0WNx.   .kMMMk.   .dWMMNl   .kMMMMMMMXk0c   .kMMMMMMMO.   .dNNNNNNNNWMMMMMMMNc    :NMMMMMWo    .oXWXo.   ;KMMMO'    lNNNNNNNNN    //
//    .   .OMMWo    ;XMX;   .xMMMWo    oWMMx.   .kMMMWx. .;OMMMMMMMXOd'   '0MMMMMMMO.   .kMMMMMMMMMMMMMMMMMk.   .OMMMMMNc    .OMMMN:   ;KMMMO.    oWMMMMMMMM    //
//    .   .OMMWo    '0M0'   .xMMMWd.   :XMMk.   .xMMMMXkkKNMMMMMMMMXko.   ;XMMMMMMMO.   .xWMMMMMMMMMMMMNxdXK;    oWMMMMNc    .OMMMWxcokKWMMMO.   .dWMMMMMMMM    //
//        .OMMWo    .OMO.   .xMMMMd.   '0MMO.   .dWMMMMMMMMMMMMMMMWNXk,   :XMMMMMMMO.    .;::ckWMMMMMMM0'.OWo    ;KMMMMNc    .OMMMMMMMMMMMMMO.    ,c:::cOWMM    //
//        '0MMWl    'OMO.   .xMMMMd.   .OMMO.    oWMMMMMMWMMMMMNXKOc..    .o0XWMMMMO.         cNMMMMMMWd..dW0'   .xMMMMNc    .OMMMMMMMMMMMMMO.          oWMM    //
//        .OMMNc    '0MO.   .dMMMWd.   .OMMO.    dWMXo::;;cOWMMMWWNl       ,ONWMMMMO.    .....oNMMMMMMX;  cNN:    :NMMMNc    .OMMMMMMMMMMMMMO.         .dWMM    //
//        .OMMWl    '0M0'    oWMMWo    '0MMO.    dWMO'     cNMMMMMWo       :NMMMMMMO.   .xKKKXNMMMMMMMk.  ,KWd.   .OMMMN:    '0MMMMMMMMMMMMMO.    :kOOO0NMMM    //
//        .OMMWl    '0MK;    oWMMWo    ,KMMk.    oWMK;     :XMMMMMWo       lWMMMMMMO.   '0MMMMMMMMMMMNl   .kWk.    lWMMX;    '0MMMWkcoxKWMMMO.    oWMMMMMMMM    //
//        .OMMNc    ;KMNc    lWMMWd.   ;KMMk.    lWMWXl.   ;XMMMMMWo       oWMMMMMMO.   '0MMMMMMMMMMM0,   .OK;     ,KMMX:    '0MMMNc   '0MMMO.    oWMMMMMMMM    //
//        .OMWK;    lNMWd.   ;KMMXc    cNMM0'    ;KMMNl    ,KMMMMMWo       dWMMMMMMO.   '0MMMMMMMMMMWd.   ;Kx.     .dWMNc    .kMMWK;   'OMMMO.    l00KKXKKKX    //
//        .ONo.    '0MMM0,    ,0Xc    .xMMMNo     ;0Xc     ;XMMMMMWo      .dMMMMMMMk.   '0MMMMMMMMMMX:    lN0o:.    ;XMWd.    ,0Wx.    lNMMMO.     ........,    //
//        .kX:    ,OWMMMWk.   .dK;   .lXMMMMXo.   .xO'     ;XMMMMMWd      .xMMMMMMMk.   '0MMMMMMMMMMk.   .xMMMNl    .OMMNd.    lXl    :KMMMMO.             .    //
//    ....:KNo..:xXMMMMMMW0o,.'kNo.'lOWMMMMMMW0o;..x0:.';,.:XMMMMMWd      .xMMMMMMMO,...:KMMMMMMMMMWd....:KMMMMO;...'xWMMWKd;..dXo.':xXMMMMM0;.............,    //
//    XKKXWMWNKNWMMMMMMMMMMMWXXNMNXNMMMMMMMMMMMMWXXNWNXNWN0KWMMMMMWd      .xMMMMMMMWXXXXXWMMMMMMMMMMNKKKXWMMMMMWNXXXXNMMMMMMWKKNWNXNWMMMMMMMWNXXXKKKKKKK000K    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd      .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.     .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl    .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:.c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNddNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DFAC is ERC1155Creator {
    constructor() ERC1155Creator("Dogface Comic Strip", "DFAC") {}
}