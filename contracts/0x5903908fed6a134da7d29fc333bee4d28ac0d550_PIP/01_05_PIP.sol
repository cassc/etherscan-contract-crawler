// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vinnie M
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Colors, shapes, and WTF...    //
//                                  //
//                                  //
//////////////////////////////////////


contract PIP is ERC721Creator {
    constructor() ERC721Creator("Vinnie M", "PIP") {}
}