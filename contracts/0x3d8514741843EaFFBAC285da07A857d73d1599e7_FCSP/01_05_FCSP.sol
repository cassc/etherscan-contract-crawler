// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flower Child Slumber Party ETH Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    FCSP    //
//            //
//            //
////////////////


contract FCSP is ERC721Creator {
    constructor() ERC721Creator("Flower Child Slumber Party ETH Editions", "FCSP") {}
}