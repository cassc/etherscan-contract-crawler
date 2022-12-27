// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AC1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    AC1    //
//           //
//           //
///////////////


contract AC1 is ERC721Creator {
    constructor() ERC721Creator("AC1", "AC1") {}
}