// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PNT22 MOSAIC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//     ..........................................................      //
//     cPPPPPPPPPPPPPPPPPPPPPPPPPPANOTTTTTTTTTTTTTTTTTTTTTTTTTTT0l     //
//     oWMMMMMMMMMMMMMMMMMMMMMMMMOSAICMMMMMMMMMMMMMMMMMMMMMMMMMWd.     //
//     oWMMMMMMMMMMMWNKOkkxkO0XWMMMMMMMMWX0OkkkkOKNWMMMMMMMMMMMWd.     //
//     oWMMMMMMMMNOo:'.      ..,cxKWWXxc,..      ..;oONMMMMMMMMMd.     //
//     oWMMMMMMNx;.    .',,'..    .,;.    ..',,'.     ,xNMMMMMMMd.     //
//     oWMMMMMKc    .lkKNWWNX0d;.      .;d0XNWWNKkl'    :KMMMMMMd.     //
//     oWMMMMNc    :KWMMMMMMMNKx,      'xKNWMMMMMMMKc    :XMMMMMd.     //
//     oWMMMM0'   .OMMMMMMXkc'.          .'cxXMMMMMM0'   .OMMMMMd.     //
//     oWMMMMK,   .dWMMMNx'    .';cccc:'.    'dXMMMWx.   ,0MMMMMd.     //
//     oWMMMMWx.   .lKWXc    'o0NWMMMMMN0d'    :KWKo.   .dWMMMMMd.     //
//     oWMMMMMWO;    .;,    ;KMMMMMMMMMMMMK:    ';.    ,kWMMMMMMd.     //
//     oWMMMMMMMK:         .dWMMMMMMMMMMMMMx.         ;KMMMMMMMMd.     //
//     oWMMMMMW0:.   .,'    :KMMMMMMMMMMMMXc    .,.    ;OWMMMMMMd.     //
//     oWMMMMWk.   .c0NK:    ,dKWMMMMMMWKx,    ;0N0l.   .xWMMMMMd.     //
//     oWMMMMK;   .dWMMMXd.    .,:llllc,.    .oXMMMWx.   ,KMMMMMd.     //
//     oWMMMM0'   .OMMMMMWXx:.            .:dKWMMMMM0'   .OMMMMMd.     //
//     oWMMMMNc    cXMMMMMMMWX0d,      'd0XWMMMMMMMXc    :XMMMMMd.     //
//     oWMMMMMK:    'oOXWWWWNKk:.      .:xKNWWWWX0o'    ;0MMMMMMd.     //
//     oWMMMMMMNd'     .,;;,'.    .''.    .',;;,..    'dXMMMMMMMd.     //
//     oWMMMMMMMMNkl,..       .':dKNNKd:'.        .,lkXMMMMMMMMWd.     //
//     oWMMMMMMMMMMMWX0kxxdxkOKNWMMMMMMWNKOkxddxk0XWMMMMMMMMMMMWd.     //
//     oWMMMMMMMMMMMMMMMMMMMMMMMMM2022MMMMMMMMMMMMMMMMMMMMMMMMMMd.     //
//     lKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl      //
//     .''''''''''''''''''''''''''''''''''''''''''''''''''''''''.      //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract PNT22M is ERC1155Creator {
    constructor() ERC1155Creator("PNT22 MOSAIC", "PNT22M") {}
}