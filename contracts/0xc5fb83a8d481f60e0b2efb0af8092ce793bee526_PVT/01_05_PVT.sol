// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pro Veritas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    _|_|_|    _|      _|  _|_|_|_|_|      //
//    _|    _|  _|      _|      _|          //
//    _|_|_|    _|      _|      _|          //
//    _|          _|  _|        _|          //
//    _|            _|          _|          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract PVT is ERC721Creator {
    constructor() ERC721Creator("Pro Veritas", "PVT") {}
}