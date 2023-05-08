// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mad dog jaws
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    0-'    //
//           //
//           //
///////////////


contract DOG is ERC721Creator {
    constructor() ERC721Creator("mad dog jaws", "DOG") {}
}