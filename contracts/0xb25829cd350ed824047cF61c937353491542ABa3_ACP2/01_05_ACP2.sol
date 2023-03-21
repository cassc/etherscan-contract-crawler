// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlexCollabProject2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Alex Collab    //
//                   //
//                   //
///////////////////////


contract ACP2 is ERC721Creator {
    constructor() ERC721Creator("AlexCollabProject2", "ACP2") {}
}