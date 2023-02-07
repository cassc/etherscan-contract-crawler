// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: masons pixels
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                      _         _         //
//     _____ ___ ___ ___ ___ ___    ___|_|_ _ ___| |___     //
//    |     | .'|_ -| . |   |_ -|  | . | |_'_| -_| |_ -|    //
//    |_|_|_|__,|___|___|_|_|___|  |  _|_|_,_|___|_|___|    //
//                                 |_|                      //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract PIXEL is ERC721Creator {
    constructor() ERC721Creator("masons pixels", "PIXEL") {}
}