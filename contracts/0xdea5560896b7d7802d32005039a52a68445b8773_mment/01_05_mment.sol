// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moment
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract mment is ERC721Creator {
    constructor() ERC721Creator("Moment", "mment") {}
}