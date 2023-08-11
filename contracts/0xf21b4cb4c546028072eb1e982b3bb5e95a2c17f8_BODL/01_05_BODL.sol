// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BODL Collab Series
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    _|_|_|      _|_|    _|_|_|    _|            //
//    _|    _|  _|    _|  _|    _|  _|            //
//    _|_|_|    _|    _|  _|    _|  _|            //
//    _|    _|  _|    _|  _|    _|  _|            //
//    _|_|_|      _|_|    _|_|_|    _|_|_|_|      //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract BODL is ERC721Creator {
    constructor() ERC721Creator("BODL Collab Series", "BODL") {}
}