// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Time High
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ATH    //
//           //
//           //
///////////////


contract ATH is ERC721Creator {
    constructor() ERC721Creator("All Time High", "ATH") {}
}