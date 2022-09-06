// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOR
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    lof    //
//           //
//           //
///////////////


contract LOR is ERC721Creator {
    constructor() ERC721Creator("LOR", "LOR") {}
}