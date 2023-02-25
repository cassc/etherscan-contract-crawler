// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Damaged Goods
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//     _|_|_|    _|      _|    _|_|_|      //
//     _|    _|  _|_|  _|_|  _|            //
//     _|    _|  _|  _|  _|  _|  _|_|      //
//     _|    _|  _|      _|  _|    _|      //
//     _|_|_|    _|      _|    _|_|_|      //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract DMG is ERC721Creator {
    constructor() ERC721Creator("Damaged Goods", "DMG") {}
}