// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Condo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    CONDO    //
//             //
//             //
/////////////////


contract CONDO is ERC721Creator {
    constructor() ERC721Creator("Condo", "CONDO") {}
}