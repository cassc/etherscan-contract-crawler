// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solace 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//      ___|          |                        //
//    \___ \    _ \   |   _` |   __|   _ \     //
//          |  (   |  |  (   |  (      __/     //
//    _____/  \___/  _| \__,_| \___| \___|     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract SLCE is ERC721Creator {
    constructor() ERC721Creator("Solace 1/1s", "SLCE") {}
}