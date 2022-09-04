// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PANOT FLOR 2022
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNKkdlcc:clox0NMMMMMWN0xolccccldkKWMMMMMMMM    //
//    MMMMMNOl,.          .'ckK0x:.           .,l0WMMMMM    //
//    MMMWO;    .':loolc,.    ..    .,clool:'    .:0WMMM    //
//    MMWx.   .cONMMMMMMW0o.      'dKWMMMMMMNO:.   .kWMM    //
//    MM0'   .xWMMMMMMMNOdl'      'lx0NMMMMMMMWd.   ,KMM    //
//    MMk.   ,KMMMMMNOc'             .'lOWMMMMM0'   .OMM    //
//    MM0'   .dNMMW0:    .,coxxxdoc,.   .cKMMMNo.   ;KMM    //
//    MMWk.   .:kXO'   .c0NMMMMMMMMNO:    ,0Xk;    'OMMM    //
//    MMMW0:.    ..    lWMMMMMMMMMMMMNc    ..    .cKMMMM    //
//    MMMMW0;         .xMMMMMMMMMMMMMMd.         :KMMMMM    //
//    MMMNd.    'c,    ;KMMMMMMMMMMMM0,    ;c'    .xNMMM    //
//    MMNl    'kNMXc    .oOXWMMMMWXOl.    lXMNx.   .oWMM    //
//    MMO.   .OMMMMNx,     .,;::;,.     ,kNMMMMk.   '0MM    //
//    MMk.   '0MMMMMMNOl,.          .;lONMMMMMMO'   .OMM    //
//    MMX:    cXMMMMMMMMWXk,      ,kXWMMMMMMMMK:    cNMM    //
//    MMMK;    .lkKNWWNKOo,        ,dOXNWWNKkc.    :KMMM    //
//    MMMMNx,     .''''.     ':;.     .'''..    .;kNMMMM    //
//    MMMMMMNOo;'.      ..;lkXWWXkl,..      .':o0NMMMMMM    //
//    MMMMMMMMMWNKOOkkkO0XWMMMMMMMMWX0OkkkOOKNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract PNT22 is ERC721Creator {
    constructor() ERC721Creator("PANOT FLOR 2022", "PNT22") {}
}