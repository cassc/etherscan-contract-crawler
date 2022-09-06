// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Storm 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    This is the official contract of storm 1/1    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract strm is ERC721Creator {
    constructor() ERC721Creator("Storm 1/1", "strm") {}
}