// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TanuKingdom
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (´・ω・`)    //
//               //
//               //
///////////////////


contract Tanuki is ERC721Creator {
    constructor() ERC721Creator("TanuKingdom", "Tanuki") {}
}