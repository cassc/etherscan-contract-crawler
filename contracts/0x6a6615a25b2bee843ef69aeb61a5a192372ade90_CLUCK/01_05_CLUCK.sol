// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New PFP, Who Dis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Its a Chicken.....    //
//                          //
//                          //
//////////////////////////////


contract CLUCK is ERC721Creator {
    constructor() ERC721Creator("New PFP, Who Dis", "CLUCK") {}
}