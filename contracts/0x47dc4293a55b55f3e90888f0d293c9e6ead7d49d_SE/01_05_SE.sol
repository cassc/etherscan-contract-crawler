// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oveck Special Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Oveck    //
//             //
//             //
/////////////////


contract SE is ERC721Creator {
    constructor() ERC721Creator("Oveck Special Editions", "SE") {}
}