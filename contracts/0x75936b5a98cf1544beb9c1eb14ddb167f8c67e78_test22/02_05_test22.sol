// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST22
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    TEST22    //
//              //
//              //
//////////////////


contract test22 is ERC721Creator {
    constructor() ERC721Creator("TEST22", "test22") {}
}