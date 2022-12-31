// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solace Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract SLCE is ERC1155Creator {
    constructor() ERC1155Creator("Solace Editions", "SLCE") {}
}