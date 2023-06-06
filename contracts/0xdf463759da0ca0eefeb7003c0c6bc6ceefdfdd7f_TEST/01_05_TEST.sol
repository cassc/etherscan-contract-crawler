// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST 721 - 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    TEST1    //
//             //
//             //
/////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("TEST 721 - 1", "TEST") {}
}