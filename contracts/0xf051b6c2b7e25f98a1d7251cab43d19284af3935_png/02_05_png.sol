// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jpeg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract png is ERC721Creator {
    constructor() ERC721Creator("Jpeg", "png") {}
}