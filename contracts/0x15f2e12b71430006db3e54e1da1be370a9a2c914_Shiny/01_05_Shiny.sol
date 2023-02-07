// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiny Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ✨    //
//         //
//         //
/////////////


contract Shiny is ERC721Creator {
    constructor() ERC721Creator("Shiny Editions", "Shiny") {}
}