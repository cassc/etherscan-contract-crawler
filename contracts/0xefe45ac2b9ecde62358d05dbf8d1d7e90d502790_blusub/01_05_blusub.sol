// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blue Suburban
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Blue Suburban    //
//                     //
//                     //
/////////////////////////


contract blusub is ERC721Creator {
    constructor() ERC721Creator("Blue Suburban", "blusub") {}
}