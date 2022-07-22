// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Real Appropriate
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Clearing__Contract    //
//                          //
//                          //
//////////////////////////////


contract REAL is ERC721Creator {
    constructor() ERC721Creator("Real Appropriate", "REAL") {}
}