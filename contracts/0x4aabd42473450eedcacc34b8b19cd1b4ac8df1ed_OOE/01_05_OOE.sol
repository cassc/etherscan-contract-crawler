// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oveck OE Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Oveck    //
//             //
//             //
/////////////////


contract OOE is ERC721Creator {
    constructor() ERC721Creator("Oveck OE Edition", "OOE") {}
}