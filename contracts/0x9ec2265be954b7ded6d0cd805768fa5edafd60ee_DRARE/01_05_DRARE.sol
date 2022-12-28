// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dinos Rarities
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Rarities    //
//                //
//                //
////////////////////


contract DRARE is ERC721Creator {
    constructor() ERC721Creator("Dinos Rarities", "DRARE") {}
}