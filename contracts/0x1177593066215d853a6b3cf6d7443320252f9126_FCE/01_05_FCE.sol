// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fabric Collage Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    _|_|_|_|    _|_|_|  _|_|_|_|      //
//    _|        _|        _|            //
//    _|_|_|    _|        _|_|_|        //
//    _|        _|        _|            //
//    _|          _|_|_|  _|_|_|_|      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract FCE is ERC721Creator {
    constructor() ERC721Creator("Fabric Collage Editions", "FCE") {}
}