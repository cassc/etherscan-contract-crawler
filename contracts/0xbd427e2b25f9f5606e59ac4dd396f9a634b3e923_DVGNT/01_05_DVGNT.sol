// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DIVERGENT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract DVGNT is ERC721Creator {
    constructor() ERC721Creator("DIVERGENT", "DVGNT") {}
}