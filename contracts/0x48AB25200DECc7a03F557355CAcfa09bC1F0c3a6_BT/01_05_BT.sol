// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlankTesting
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    -    //
//         //
//         //
/////////////


contract BT is ERC721Creator {
    constructor() ERC721Creator("BlankTesting", "BT") {}
}