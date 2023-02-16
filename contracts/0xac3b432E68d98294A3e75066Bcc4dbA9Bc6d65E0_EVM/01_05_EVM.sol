// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everman Shoots
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    Evm    //
//           //
//           //
///////////////


contract EVM is ERC721Creator {
    constructor() ERC721Creator("Everman Shoots", "EVM") {}
}