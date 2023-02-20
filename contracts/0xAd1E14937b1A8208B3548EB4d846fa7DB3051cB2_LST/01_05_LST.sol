// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lindos Soul Token
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                             .,;;,.                                                             //
//                                                           ;kXWMMWXk;                                                           //
//                                                          :NMMMMMMMMN:                                                          //
//                                                          oMMMMMMMMMMo                                                          //
//                                                        .:kWX0XMMX0XWk:.                                                        //
//                                                        .;lKWXK00KXWKl;.                                                        //
//                                                           .dKK00KKd.                                                           //
//                                                          ..;x0000x;..                                                          //
//                                                       'lkKXWMWWWWMWXKkl'                                                       //
//                                                    .;xNWWWMMMMMMMMMMWWWNx;.                                                    //
//                                                  .l0NKd;:0MMMMMMMMMM0:;dKN0l.                                                  //
//                                                ,dXNOc.  .kMMMMMMMMMMk.  .cONXd,                                                //
//                                         ....'cOX0o,     .kMMMMMMMMMMk.     ,o0XOc'....                                         //
//                                         'oxOXWO:.       .OMMMMMMMMMMO.       .:OWXOxo'                                         //
//                                       .':xOKKo.         '0MMMMMMMMMM0'         .oKKOx:'.                                       //
//                                        .,coo:.          ,KMMMMMMMMMMK,          .:ooc,.                                        //
//                                          ..             ;XMMMMMMMMMMX;             ..                                          //
//                                                         ;XMMMMMMMMMMX;                                                         //
//                                                         ;XMMMMMMMMMMX;                                                         //
//                                                         :NMMX0OO0XMMN:                                                         //
//                                                         :NMMNl..lNMMN:                                                         //
//                                                         '0MMN:  :NMM0'                                                         //
//                                                         .kMMO.  .OMMk.                                                         //
//                                                         .xMWl    lWMx.                                                         //
//                                                         .xMX;    ;XMx.                                                         //
//                                                         .kMX;    ;XMk.                                                         //
//                                                         .kMX;    ;XMk.                                                         //
//                                                         .xM0'    '0Mx.                                                         //
//                                                          oWO.    .OWo                                                          //
//                                                          oWK;    ;KWo                                                          //
//                                                         ,KMWl    lWMK,                                                         //
//                                                        .dNNNx.  .xNNNd.                                                        //
//                                                         .''''.  .''''.                                                         //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LST is ERC721Creator {
    constructor() ERC721Creator("Lindos Soul Token", "LST") {}
}