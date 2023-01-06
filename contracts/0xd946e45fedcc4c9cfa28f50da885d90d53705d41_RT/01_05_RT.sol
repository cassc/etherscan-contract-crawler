// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reaper Town
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    RT    //
//          //
//          //
//////////////


contract RT is ERC721Creator {
    constructor() ERC721Creator("Reaper Town", "RT") {}
}