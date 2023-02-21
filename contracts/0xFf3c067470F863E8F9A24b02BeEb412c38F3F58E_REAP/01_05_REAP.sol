// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reaper
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    REAP    //
//            //
//            //
////////////////


contract REAP is ERC721Creator {
    constructor() ERC721Creator("Reaper", "REAP") {}
}