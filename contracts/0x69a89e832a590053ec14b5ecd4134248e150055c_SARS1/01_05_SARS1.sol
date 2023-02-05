// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SarcasticSongs1of1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    "$"    //
//           //
//           //
///////////////


contract SARS1 is ERC721Creator {
    constructor() ERC721Creator("SarcasticSongs1of1s", "SARS1") {}
}