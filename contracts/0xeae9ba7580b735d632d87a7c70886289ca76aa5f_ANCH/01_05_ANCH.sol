// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anchorball
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMWX0kdl:;'..............,:coxOKNWMMMMMMMMMMMMWX0kdlc;,'..........',;:codk0XNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWN0xl;'.                         ..':lx0XWMMWN0xl;'.                         ..,cokKNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKxc,.                                    .':llc,.                                    .,cx0NMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0d:.                                                                                        .,oONMMMMMMMMMMM    //
//    MMMMMMMMMXk:.                                                                                              .,o0WMMMMMMMM    //
//    MMMMMMWKd,.                                                                                                   .:xXMMMMMM    //
//    MMMMWKo'                            .......                                  ..........                         .,xXMMMM    //
//    MMMXd'                        .;ldxO00KKK0Okxl'                          'lxkO0KKXXXKK0ko,.                       .,kNMM    //
//    MWk;.                        'xNMMMMMMMMMMMMNd.                          .dNMMMMMMMMMMMMMXc                         .lKM    //
//    Xl.                         'OWMMMMMMMMMMMMXl.                            .:KMMMMMMMMMMMMWd.   .:ol,.                 ;0    //
//    c.               .'.       .dWMMMMMMMMMMMMK:.                               ,OWMMMMMMMMMMWd.  .dNMMNOl'                ;    //
//    Kd:.           'o0NKc.     ,0MMMMMMMMMMMM0;               ';;.               'kWMMMMMMMMMWd.  :XMMMMMWXd,           .;oO    //
//    MMWKxc'.     .lKWMMMk.     :XMMMMMMMMMMMK;              .lKWWKo'              'OWMMMMMMMMWd. .oWMMMMMMMMXl.     ..:xKWMM    //
//    MMMMMWXOo;..'xWMMMMMK,     lWMMMMMMMMMMX:              ,kWMMMMWKc.             ,0MMMMMMMMWd. .kMMMMMMMMMMWk,..,lkXWMMMMM    //
//    MMMMMMMMMWKOKWMMMMMMX:    .dWMMMMMMMMMNl.             ;0WMMMMMMMNo.             :XMMMMMMMWd. 'OMMMMMMMMMMMWKk0NMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMX:    .xMMMMMMMMMWx.             ;KMMMMMMMMMMNo.            .dWMMMMMMWd. ,0MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNc    .OMMMMMMMMMX:             'OMMMMMMMMMMMMX:             ,0MMMMMMWo. ;KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWo.   ;KMMMMMMMMMk.            .dWMMMMMMMMMMMMMk.            .dWMMMMMWo. :XMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWd.  .oWMMMMMMMMNl             ;KMMMMMMMMMMMMMMX:             :XMMMMMWo. cNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0:.'oXMMMMMMMMMX:            .oWMMMMMMMMMMMMMMWd.            ,0MMMMMWo. lNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNXXWMMMMMMMMMM0,            .kMMMMMMMMMMMMMMMMk.            .kMMMMMWd..oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'            'OMMMMMMMMMMMMMMMMO'            .xMMMMMWx..xMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'            'OMMMMMMMMMMMMMMMMO'            .dWMMMMMk..kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'            .kMMMMMMMMMMMMMMMMO.            .dWMMMMMO',0MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,            .dWMMMMMMMMMMMMMMWd.            .xMMMMMMNxxNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:             :XMMMMMMMMMMMMMMNc             'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.            .kMMMMMMMMMMMMMMO'             :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'             :KMMMMMMMMMMMMNl.            .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.            .lNMMMMMMMMMMWx.             :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWX0XMMMMMMMMMMMMMMMMMMMMMMMMM0,             .lXMMMMMMMMWk'             'OMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMM    //
//    MMMMMMWKxc..:0WMMMMMMMMMMMMMMMMMMMMMMMWk'             .:KWMMMMMNd.             .xWMMMMMMMMMMMMMMMMMMMMMMMMNd'':d0NMMMMMM    //
//    MMMN0d:.     'xNMMMMMMMMMMMMMMMMMMMMMMMWk'              'xXMMW0:.             .xWMMMMMMMMMMMMMMMMMMMMMMMWO:.    .,oONWMM    //
//    Kkl,.         .:ONMMMMMMMMMMMMMMMMMMMMMMWk'              .,lo:.              .xWMMMMMMMMMMMMMMMMMMMMMMW0c.         .,lkK    //
//    :.              .:kNMMMMMMMMMMMMMMMMMMMMMWO,                                'kWMMMMMMMMMMMMMMMMMMMMMNOc.              .:    //
//    k'                .,oONMMMMMMMMMMMMMMMMMMMMKc.                             ,OWMMMMMMMMMMMMMMMMMMMN0o,.                ;0    //
//    Wk'                  .,lx0NWMMMMMMMMMMMMMMMMXd.                          .:KMMMMMMMMMMMMMMMMWNKxl,.                 .oXM    //
//    MW0;                     .,:oxO0KXNNWWWNNNXK0x;.                         'xKXNNWWWWWWNXX0Oxoc,.                   .;OWMM    //
//    MMM0,                         ...'',,;,,,'...                             ...',;;;;;,,'...                        :XMMMM    //
//    MMMNo.                                                                                                           .dWMMMM    //
//    MMMMx.  ,l,                                                                                                      .xMMMMM    //
//    MMMMk. .dW0,                                                                                               .;c,  .xMMMMM    //
//    MMMMk. .xWNc                                              ...                                            .:OWMk. .xMMMMM    //
//    MMMMO' .kMWo.   .,oxo;.                                  .dOd,                                           ;KMMMO' .xMMMMM    //
//    MMMMK; ;KMWo.   cXMMMNOc.                     .';;,.     lNNXl   .lc.                      ..';:cc:.     cNMMM0' .xMMMMM    //
//    MMMMWx:kWMNl   .kMMMMMMNo.     .,ldoc.       'kNWWXc    .xMNXl   ,00'       .,'.        .;dOKNWMMMWO'   .dWMMM0' .xMMMMM    //
//    MMMMMWWMMMNl   .kMMMMMMMk.    .oXMMMWK:.     lNMMMWo.   .kMNXl   ,0K;      'kNXo.     .:ONMMMMMMMMMX:   .kMMMMK; .OMMMMM    //
//    MMMMMMMMMMNl   .kMMMMMMMk.   .dWMMMMMMX:    .dWMMMWo.   .xMWNd.  :XK;     .xWMMX:     cXMMMMMMMMMMMNc   '0MMMMWOlxNMMMMM    //
//    MMMMMMMMMMNl   .kMMMMMMMk.  .lNMMMMMMMMk.   .dWMMMWl.   .xMMMO' .oW0,     :XMMMWx.   .xWMMMMMMMMMMMWl   ,0MMMMMMWMMMMMMM    //
//    MMMMMMMMMMNl   .OMMMMMMMx.  'OMMMMMMMMMK;   .dWMMMWo.   .kMMMXc 'OM0,    .lWMMMMx.   .xMMMMMMMMMMMMNl   ,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMNl   .OMMMMMMMx.  :XMMMMMMMMMX:   .dMMMMMx.   'OMMMMKxONM0,    .kMMMMMx.   .xWMMMMMMMMMMMNl   ,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMNl   'OMMMMMMMx.  lNMMMMMMMMMNl   .kMMMMM0'   :XMMMMMMMMM0,    ;KMMMMWx.   .dWMMMMMMMMMMMNl   ,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMNl   'OMMMMMMMx. .dWMMMMMMMMMWo.  .kMMMMMNo. .xWMMMMMMMMM0,   .dWMMMMWx.   .dWMMMMMMMMMMMNl   ,0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMNl   '0MMMMMMMx. .xMMMMMMMMMMWd.  .kMMMMMMNOdOWMMMMMMMMMM0,   .kMMMMMMx.   .dWMMMMMMMMMMMWl.  ,KMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANCH is ERC721Creator {
    constructor() ERC721Creator("Anchorball", "ANCH") {}
}