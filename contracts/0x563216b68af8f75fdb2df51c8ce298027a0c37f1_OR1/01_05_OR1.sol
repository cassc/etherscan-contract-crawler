// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oveck 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Oveck    //
//             //
//             //
/////////////////


contract OR1 is ERC721Creator {
    constructor() ERC721Creator("Oveck 1/1s", "OR1") {}
}