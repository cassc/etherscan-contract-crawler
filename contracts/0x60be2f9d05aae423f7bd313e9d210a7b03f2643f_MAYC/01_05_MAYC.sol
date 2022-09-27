// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burger Avenue
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    S/F    //
//           //
//           //
///////////////


contract MAYC is ERC721Creator {
    constructor() ERC721Creator("Burger Avenue", "MAYC") {}
}