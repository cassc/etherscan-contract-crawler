// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The O
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ○    //
//         //
//         //
/////////////


contract TheO is ERC721Creator {
    constructor() ERC721Creator("The O", "TheO") {}
}