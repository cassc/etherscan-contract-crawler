// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bay Backner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    BAY    //
//           //
//           //
///////////////


contract BAY is ERC721Creator {
    constructor() ERC721Creator("Bay Backner", "BAY") {}
}