// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Surprise by yuck
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    &:)    //
//           //
//           //
///////////////


contract SS is ERC721Creator {
    constructor() ERC721Creator("Super Surprise by yuck", "SS") {}
}