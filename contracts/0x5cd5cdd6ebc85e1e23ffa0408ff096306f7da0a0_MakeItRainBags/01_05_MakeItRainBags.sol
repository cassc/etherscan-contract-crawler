// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raining Bags
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    roof    //
//            //
//            //
////////////////


contract MakeItRainBags is ERC721Creator {
    constructor() ERC721Creator("Raining Bags", "MakeItRainBags") {}
}