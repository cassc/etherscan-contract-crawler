// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ben Rug Yacht Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Walmart knows    //
//                     //
//                     //
/////////////////////////


contract BRYC is ERC721Creator {
    constructor() ERC721Creator("Ben Rug Yacht Club", "BRYC") {}
}