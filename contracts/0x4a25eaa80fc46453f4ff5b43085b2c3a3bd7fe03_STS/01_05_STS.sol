// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stairway to the subway
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    (￣ー￣)    //
//             //
//             //
/////////////////


contract STS is ERC721Creator {
    constructor() ERC721Creator("Stairway to the subway", "STS") {}
}