// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D & T Limited Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     _|_|_|          _|            _|_|_|_|_|      //
//     _|    _|      _|  _|              _|          //
//     _|    _|        _|_|  _|          _|          //
//     _|    _|      _|    _|            _|          //
//     _|_|_|          _|_|  _|          _|          //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract DTLTD is ERC721Creator {
    constructor() ERC721Creator("D & T Limited Editions", "DTLTD") {}
}