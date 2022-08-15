// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Joey
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Super Joey Foundation    //
//                             //
//                             //
/////////////////////////////////


contract JOEY is ERC721Creator {
    constructor() ERC721Creator("Super Joey", "JOEY") {}
}