// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VIS Rares
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    _|      _|  _|_|_|    _|_|_|      //
//    _|      _|    _|    _|            //
//    _|      _|    _|      _|_|        //
//      _|  _|      _|          _|      //
//        _|      _|_|_|  _|_|_|        //
//                                      //
//                                      //
//////////////////////////////////////////


contract VIS is ERC721Creator {
    constructor() ERC721Creator("VIS Rares", "VIS") {}
}