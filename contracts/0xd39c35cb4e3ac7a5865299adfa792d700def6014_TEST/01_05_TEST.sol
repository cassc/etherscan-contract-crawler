// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Edition Testing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    TESTING    //
//               //
//               //
///////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("Edition Testing", "TEST") {}
}