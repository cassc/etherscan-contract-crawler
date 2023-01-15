// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ruri Box
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    📦    //
//          //
//          //
//////////////


contract RRB is ERC721Creator {
    constructor() ERC721Creator("Ruri Box", "RRB") {}
}