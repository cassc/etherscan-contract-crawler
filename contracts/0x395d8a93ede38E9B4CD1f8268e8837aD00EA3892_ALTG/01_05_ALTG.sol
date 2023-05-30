// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAZE OF MIND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//       _|_|    _|    _|_|_|_|_|    _|_|_|              //
//     _|    _|  _|        _|      _|                    //
//     _|_|_|_|  _|        _|      _|  _|_|              //
//     _|    _|  _|        _|      _|    _|              //
//     _|    _|  _|_|_|_|  _|        _|_|_|              //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract ALTG is ERC721Creator {
    constructor() ERC721Creator("MAZE OF MIND", "ALTG") {}
}