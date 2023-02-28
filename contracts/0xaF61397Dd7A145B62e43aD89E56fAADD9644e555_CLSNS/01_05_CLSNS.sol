// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collisions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    XKOKWWWWWWWWWWWNNNNNNNNNXXXXXXXXXXXXXXXXXXO;            ,OXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNWWWWWWNOOXN    //
//    MXkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.           lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOOWM    //
//    MNOKMMMMKdlllllllllooooooooooooooooooooodONNxlccclsnscldKW0dooooooooooooooooooooolloooooood0WMMW00WM    //
//    WXOKMMMNc                                .OMMMMMMMMMMMMMMX:                                '0MMW00WW    //
//    ;:cOWMMX:                                .OMMMMMMMMMMMMMMX;                                .OMMMKo;,    //
//       :NMMN:                                'OMMMMMMMMMMMMMMX:                                .OMMMd.      //
//       ;XMMN:                                '0MMXo::::::dXMMX:                                '0MMWd       //
//       ;KMMNc                                ,0MWd.      .xWMX:                                '0MMWo       //
//       ,KMMNc                                ,KKl.        .:0Nc                                '0MMWl       //
//       '0MMNc                              .:xNd.          .dWOc,                              ,0MMNl       //
//       '0MMNc                             .xMMWd            dWMMK,                             ,KMMNc       //
//       .OMMWo                             .OMMWd            lWMMK;                             :XMMX:       //
//        ,loOKxdc.                      'clk0kdl'            .:coOOol;.                     .:od00ol:.       //
//           '0MMNc                     .OMMWd.                   lNMMX;                     ;KMMX:           //
//            ,lokOxdddddooooooooollllllk0xdo'                    'dk0X0olllllloooooooodddddx0Ooc;.           //
//               'OMMMMMMMMMMMMMMMMMMMMMWo                           .dWMMMMMMMMMMMMMMMMMMMMMK;               //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLSNS is ERC721Creator {
    constructor() ERC721Creator("Collisions", "CLSNS") {}
}