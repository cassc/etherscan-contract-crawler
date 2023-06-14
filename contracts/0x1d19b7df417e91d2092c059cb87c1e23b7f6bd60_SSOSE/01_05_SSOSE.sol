// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: School's Still Out Special Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMNkx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OO0KNWMMMMMMMMMMMMMW0d:,''';:cd0NMMMMMMMMMMMNOollx0l. ,OXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMXkc'..  ..'cxKWMMMMMMMMWO:.          .,xXMMMMMMMNx,     ..   ..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMNd'            .lKWMMMMMNo.               ,kWMMMMK:                 'oKMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMKc                .xNMMMNl                  .dNMMK;                    'kWMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMX:                  .lXMWx.                   .oNNc                      .dNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMWo          .          lNK,         ;;.         .dd.             .;.       .dWMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMM0'        .d0c.        .do.        ;KNd;.        ..              'O0;       .OMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMWd.        :XMNl         ..        .xWMWNd.                   ,,  .OMK:       :XMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMNl        .dWMMX:                  '0MMMMNc                  'kl  .kMM0,      .kMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMNc        .kMMMMO.                 ;KMMMMMO.                 lNo  .dMMWk.      lWMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMNc        .xMMMMNc                 ;XMMMMMX:                .kWx.  oWMMNc      ;XMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMWo         oWMMMMk.                ;XMMMMMWd.               ,KMO.  cNMMMk.     '0MMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMk.        ;KMMMMX;                '0MMMMMMO.               :XMK,  :XMMMX;     .kMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMK,        .dWMMMWo                .xWMMMMMK,               cNMN:  ,KMMMWo     .kMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMWd.        ,0MMMMO.                ;KMMMMMN:               :NMWo  .OMMMMx.    .xMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWKOOd'         :KMMMX:                .dWMMMMWl               ;KMMk. .kMMMMk.    .xMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMXx;.              :KMMWx.                .kWMMMMd.              .OMMK,  dWMMMO.    .kMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMW0;   .ldo;.         ;0WMK;                 .kNWMMO.               lNMNc  lWMMMk.    '0MMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMK;   'OMMMNd.         'kWW0c.    .;'         .;xNMX;               .OMMx. :XMMMd.    ;KMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMWo    oWMMMMWx.         .lKWWKkdoc::'           .lXWx.               ;KM0' ,KMMNc     cNMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMN:    oWMMMMMWO,          'xNMMXl. 'cl,           ;OXx,.         ..   :KNc .OMM0'    .xMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMNc    ;KMMMMMMMKc           :0No  ,KMMXc           .lKN0:        .c'   ;0d..xMNl     ,KMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMWx.    lNMMMMMMMNx'          .o;  ;KMMMNd.           'xNO.        cOl.  ':. oNx.     oWMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMX:     cXMMMMMMMWKc.             .oNMMMW0;            ;x:        .dN0c..:, :d'     ,0MMMNK0OKNMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMM0;     ,kNMMMMMMMWO:.            .oNMMMMNd.           .'.        .xWWXKNd...     .xWWKo;....;dXMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMK:     .:ONMMMMMMMNOc.            :0WMMMWKc.                     .lKWWNo.       lNMK;.      .cXMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMNd.     .,d0WMMMMMMW0l.     .;.   .l0WMMMWOo;                     .;;'        lXMMO'        ,0MMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWKl.      .,lxO0KKKOo.    .oXk'    .ckXWMMMNx,        ';                   .oNMMMXo.     .'xWMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMWKd,.        ....      ,xNMMKl.     'cx0KXX0l.      ;x:                 .dXWWWWWNOl:;;cdKWMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMN0dc'.            .:oddoll:.        ......        ..                 .',,;;;:::::dKMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMWNXXK0kxo:'.                       .              .;llloooooc,.....':o;.cxxxxxdddddookNMMMMMMMMMMMMMM    //    //
//    //    MMMMMMNK000Okxdolc:,'...           ....',;::cloodxkkO000xl;'......,cxKWMMMMMMMMMWXKKKXNWMO:xMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMWOc,'............',;:cclodxkkO0KXNNWWMMMMMMMMMMMMMMMMWNNXXKXNWMMMMMMMMMMMMMMMMMMMMMMXcdWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMWNXK00OO000KKXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWdlNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSOSE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}