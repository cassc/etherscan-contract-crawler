// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sakuboulabs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    策謀    //
//          //
//          //
//////////////


contract Sakubou is ERC721Creator {
    constructor() ERC721Creator("Sakuboulabs", "Sakubou") {}
}