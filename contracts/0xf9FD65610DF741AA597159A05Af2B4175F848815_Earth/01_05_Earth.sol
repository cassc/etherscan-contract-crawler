// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Earth Day 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Chainlinkpapi.eth    //
//                         //
//                         //
/////////////////////////////


contract Earth is ERC721Creator {
    constructor() ERC721Creator("Earth Day 2023", "Earth") {}
}