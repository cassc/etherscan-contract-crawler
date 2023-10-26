// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sleepy Gift
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Let there be light    //
//                          //
//                          //
//////////////////////////////


contract SLG is ERC721Creator {
    constructor() ERC721Creator("Sleepy Gift", "SLG") {}
}