// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ILLUSION ARCHITECTURE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ILA    //
//           //
//           //
///////////////


contract ILA is ERC721Creator {
    constructor() ERC721Creator("ILLUSION ARCHITECTURE", "ILA") {}
}