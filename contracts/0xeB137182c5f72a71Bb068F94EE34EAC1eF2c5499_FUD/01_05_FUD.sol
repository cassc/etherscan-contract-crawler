// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PURE FUD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract FUD is ERC721Creator {
    constructor() ERC721Creator("PURE FUD", "FUD") {}
}