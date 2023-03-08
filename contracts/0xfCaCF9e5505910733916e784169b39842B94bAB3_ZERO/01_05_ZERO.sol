// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    0    //
//         //
//         //
/////////////


contract ZERO is ERC721Creator {
    constructor() ERC721Creator("0", "ZERO") {}
}