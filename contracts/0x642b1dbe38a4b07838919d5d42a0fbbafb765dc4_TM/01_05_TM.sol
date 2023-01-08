// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Messenger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdoc:,'...                  ...';:coxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNKko:,..                                      ..,cokKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0dc'.                                                  .,cxKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOl,.                                                          .,oONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0o'                                                                 .,dKWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWO:.                                                                      .c0WMMMMMMMMMMM    //
//    MMMMMMMMMWO:.                                                                          .c0WMMMMMMMMM    //
//    MMMMMMMMKc.                                                                              .oXMMMMMMMM    //
//    MMMMMMWk'                                                                                  ,OWMMMMMM    //
//    MMMMMXo.                                                                                    .dNMMMMM    //
//    MMMMXc                                                                                       .oNMMMM    //
//    MMMXc                                                                                         .oNMMM    //
//    MMNl                                                                                           .dWMM    //
//    MWx.                                                                                            .kMM    //
//    M0,                                                                                              ;XM    //
//    Wo                                                                                               .dW    //
//    0'                                                                                                ;K    //
//    d.                                                                                                .x    //
//    ;                      .;loddolc,.                              .;loddol:,.                        c    //
//    .                    'dKWMMMMMMMWKx;.                         ,xXWMMMMMMWNKx:.                     ,    //
//    .                   cKMMMMMMMMMMMMMNk'                      .oXMMMMMMMMMMMMMW0c.                   .    //
//                       :XMMMMMMMMMMMMMMMWO'                    .dWMMMMMMMMMMMMMMMMWx.                  .    //
//                      '0MMMMMMMMMMMMMMMMMWd.                   :XMMMMMMMMMMMMMMMMMMWx.                      //
//                      cNMMMMMMMMMMMMMMMMMM0'                   lWMMMMMMMMMMMMMMMMMMMX:                      //
//                      oWMMMMMMMMMMMMMMMMMMK,                   :XMMMMMMMMMMMMMMMMMMMNc                      //
//                      :kXWMMMMMMMMMMMMMMW0l.                   .lkXWMMMMMMMMMMMMMWXkl.                      //
//                      ',.:lxO0XXNNNXKOxl;.,.                   ',..;loxkO000Okxdl;..''                 .    //
//    .                 ,c.    ........    ,c.                   'o,                 'l'                 .    //
//    :                 .do.              'xc                    .ok,               'ko.                 :    //
//    O'                 ;Od'           .;xx.                     'kk:.           .:kO,                 .x    //
//    WO'                 cdlc;'..  ..';clo,                       ;doc:;'......;cldx;                  cX    //
//    MW0c.               .:l;,:::::::;,;l,                         ,l:,;:::::::;,:l;                 .lXM    //
//    MMMNk,                'c:,......,c:.                           .:c:,.....';c:.                .;kNMM    //
//    MMMMMXc                 .;::::::;.                               .';::::::,.                .:ONMMMM    //
//    MMMMMMXc                                                                                   .xWMMMMMM    //
//    MMMMMMMO.                                                                                  lNMMMMMMM    //
//    MMMMMMMNc                                                                                 .kMMMMMMMM    //
//    MMMMMMMMO.                                                                                cXMMMMMMMM    //
//    MMMMMMMMNo.                                                                              ,0MMMMMMMMM    //
//    MMMMMMMMMNd.                                                                            ;0WMMMMMMMMM    //
//    MMMMMMMMMMWKl.                                                                        .dXMMMMMMMMMMM    //
//    MMMMMMMMMMMMW0c.                                                                    .oKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKo'                                                                ,dKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXx:.                                                          .ckNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKx:.                                                    .cxXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXkc.                                              .lkXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                                              oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                                              oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                ....''........                oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc               .;cccclcccccc:'                oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                                              oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                                              oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNc                                              oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWd.                                            .kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMK,                                            :XMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMO,                                          ;KMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.                                      .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                                  .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;.                            .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl;'.                  .':okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,..       ..';ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TM is ERC721Creator {
    constructor() ERC721Creator("The Messenger", "TM") {}
}