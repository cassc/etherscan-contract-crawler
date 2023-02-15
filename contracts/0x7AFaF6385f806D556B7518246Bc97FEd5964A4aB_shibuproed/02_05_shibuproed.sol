// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shibuプロ editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract shibuproed is ERC721Creator {
    constructor() ERC721Creator(unicode"Shibuプロ editions", "shibuproed") {}
}