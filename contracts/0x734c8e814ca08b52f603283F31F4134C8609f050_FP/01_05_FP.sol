// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foreverpunks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     _____                                     _           //
//    |   __|___ ___ ___ _ _ ___ ___ ___ _ _ ___| |_ ___     //
//    |   __| . |  _| -_| | | -_|  _| . | | |   | '_|_ -|    //
//    |__|  |___|_| |___|\_/|___|_| |  _|___|_|_|_,_|___|    //
//                                  |_|                      //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract FP is ERC721Creator {
    constructor() ERC721Creator("Foreverpunks", "FP") {}
}