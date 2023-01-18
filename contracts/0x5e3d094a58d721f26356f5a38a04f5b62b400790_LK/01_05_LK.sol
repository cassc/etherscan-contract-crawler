// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: liv + kyë
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWNNNNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXOxxxkkxdddoccldOXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKxdxxOKNWMMMMWN0xc...:dKWMMMMMMMMMMMM    //
//    MMMMMMMMMMWOodkXMMMMMMMMMMMMMMMKl.  .cOWMMMMMMMMMM    //
//    MMMMMMMMMKoo0WMMMMMMMMXdllxXMMMMWd.   .cKMMMMMMMMM    //
//    MMMMMMMWOlkWMMMMMMMMMMd    dMMMMMK,     'OWMMMMMMM    //
//    MMMMMMWkl0MMMMMMMMMMMMXxllxXMMMMMX;      .kMMMMMMM    //
//    MMMMMM0ckMMMMMMMMMMMMMMMMMMMMMMMWx.       ,KMMMMMM    //
//    MMMMMWdoNMMMMMMMMMMMMMMMMMMMMMMNd.         dMMMMMM    //
//    MMMMMXlxMMMMMMMMMMMMMMMMWMWNKOo'           :NMMMMM    //
//    MMMMMXlxMMMMMMMMMMN0dl:;,,,'.              :NMMMMM    //
//    MMMMMNodWMMMMMMMNk;.                       lWMMMMM    //
//    MMMMMMklKMMMMMMNo.                        .kMMMMMM    //
//    MMMMMMNooNMMMMMk.      .,,.               lNMMMMMM    //
//    MMMMMMMXooXMMMMd      ;XWWK;             cXMMMMMMM    //
//    MMMMMMMMXdl0WMMk.     .okko.           .oNMMMMMMMM    //
//    MMMMMMMMMWOodOWNo                    .:0WMMMMMMMMM    //
//    MMMMMMMMMMMWOddxko,                'l0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXOxxo,.         .':oONMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNKOkxddddxkOKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract LK is ERC721Creator {
    constructor() ERC721Creator(unicode"liv + kyë", "LK") {}
}