// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    1    //
//         //
//         //
/////////////


contract Test2n is ERC721Creator {
    constructor() ERC721Creator("Test2", "Test2n") {}
}