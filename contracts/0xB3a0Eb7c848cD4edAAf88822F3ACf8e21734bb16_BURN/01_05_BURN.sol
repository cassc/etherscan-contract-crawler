// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burnin Up
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    gm    //
//          //
//          //
//////////////


contract BURN is ERC721Creator {
    constructor() ERC721Creator("Burnin Up", "BURN") {}
}