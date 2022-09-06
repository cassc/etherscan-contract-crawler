// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Hello world    //
//                   //
//                   //
///////////////////////


contract TNT is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "TNT") {}
}