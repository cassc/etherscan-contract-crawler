// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wang
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Let's amaze the world together    //
//                                      //
//                                      //
//////////////////////////////////////////


contract Wang is ERC721Creator {
    constructor() ERC721Creator("Wang", "Wang") {}
}