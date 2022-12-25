// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Altava Golf Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Bayc-Bagc-Sandbox    //
//                         //
//                         //
/////////////////////////////


contract BAGC is ERC721Creator {
    constructor() ERC721Creator("Altava Golf Club", "BAGC") {}
}