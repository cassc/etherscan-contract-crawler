// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: myWorld
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    myWorld    //
//               //
//               //
///////////////////


contract myWorld is ERC721Creator {
    constructor() ERC721Creator("myWorld", "myWorld") {}
}