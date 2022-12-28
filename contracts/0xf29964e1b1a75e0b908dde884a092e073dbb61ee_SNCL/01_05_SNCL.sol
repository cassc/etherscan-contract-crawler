// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sencilla
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     ____  _   _  ____ _              //
//    / ___|| \ | |/ ___| |             //
//    \___ \|  \| | |   | |             //
//     ___) | |\  | |___| |___   __     //
//    |____/|_| \_|\____|_____| |__|    //
//                                      //
//                                      //
//////////////////////////////////////////


contract SNCL is ERC721Creator {
    constructor() ERC721Creator("Sencilla", "SNCL") {}
}