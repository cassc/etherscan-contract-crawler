// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAG
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract BAG is ERC721Creator {
    constructor() ERC721Creator("BAG", "BAG") {}
}