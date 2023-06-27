// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anti-crash_jpg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    ACRSH    //
//             //
//             //
/////////////////


contract ACRSH is ERC721Creator {
    constructor() ERC721Creator("Anti-crash_jpg", "ACRSH") {}
}