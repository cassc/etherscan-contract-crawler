// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test1DADA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    test3    //
//             //
//             //
/////////////////


contract test2 is ERC721Creator {
    constructor() ERC721Creator("test1DADA", "test2") {}
}