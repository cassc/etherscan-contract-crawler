// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bat pack
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    bat    //
//           //
//           //
///////////////


contract bat is ERC721Creator {
    constructor() ERC721Creator("bat pack", "bat") {}
}