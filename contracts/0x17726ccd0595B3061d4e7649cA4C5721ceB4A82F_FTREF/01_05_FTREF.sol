// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brimley - Future Reflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//      __|      |                                               //
//      _| |  |   _|  |  |   _| -_)                              //
//     _| \_,_| \__| \_,_| _| \___|                              //
//      _ \         _| |             |   _)                      //
//        /   -_)   _| |   -_)   _|   _|  |   _ \    \  (_-<     //
//     _|_\ \___| _|  _| \___| \__| \__| _| \___/ _| _| ___/     //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract FTREF is ERC721Creator {
    constructor() ERC721Creator("Brimley - Future Reflections", "FTREF") {}
}