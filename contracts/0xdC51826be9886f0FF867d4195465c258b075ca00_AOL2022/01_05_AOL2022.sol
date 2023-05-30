// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: An Ordinary Life
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWW0c;::::::;lKWWWWWWWWWWWWWWWWN0xo:;'......';:lx0NWWWWWWWWWNx:::::::c0WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWK;          cXWWWWWWWWWWWWWXd;.                .,oKWWWWWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWNl           .dNWWWWWWWWWWNx'                      .dXWWWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWx.            .kWWWWWWWWWXo.        ':clll:'         cXWWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWO.      ,.      ,KWWWWWWWWd.       'xXWWWWWWXx'        oNWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWK;      '0d.      cXWWWWWWK,       .kWWWWWWWWWWO.       '0WNWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWNl      .dWX:      .dNWWWWWk.       ;XWWWWWWWWWWX:       .kWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWd.      ;XWWk.      .kWWWWWx.       :NWWWWWWWWWWNc       .xWWWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWO.      .xNXNXc       ,KWWWWk.       ;XWWWWWWWWWWX;       .kWNWN:       .xWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWK;        .'..'.        cXWWWK,       .kWWWWWWWWWWO.       ,KWNWN:       .xWNWWWWWWWWWWWWWWWW    //
//    WWWWWWNl                       .oNWWWx.       .dXWWWWWWXx'       .dNWWWN:       .oKKKKKKKKKKKKXNWWWW    //
//    WWWWWWd.                        .kWWWNd.        .;cclc:.        .lXWWWWN:        .............:KWWWW    //
//    WWWWWO.       ;xkkkkkkkko.       ,0WWWNk,                      'xNWWWWWN:                     '0WWWW    //
//    WWWWK;       .OWWWWWWWWWNl        cXWWWWXx:.                .;xXWWWWWWWN:                     '0WWWW    //
//    WWWW0lccccccckNWWWWWWWWWWKocccccccoKWWWWWWWKkdl:;,,''',;:cokKNWWWWWWWWWNkcccccccccccccccccccccdXWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AOL2022 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}