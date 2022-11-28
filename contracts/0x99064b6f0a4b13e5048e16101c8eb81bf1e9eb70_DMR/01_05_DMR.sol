// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Mode Remixes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    [gmfg]    //
//              //
//              //
//////////////////


contract DMR is ERC721Creator {
    constructor() ERC721Creator("Dark Mode Remixes", "DMR") {}
}