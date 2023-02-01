// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABCCBA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ABC    //
//           //
//           //
///////////////


contract ABC is ERC721Creator {
    constructor() ERC721Creator("ABCCBA", "ABC") {}
}