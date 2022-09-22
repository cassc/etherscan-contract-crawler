// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ModelTesting
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Test and Burn!     //
//                       //
//                       //
///////////////////////////


contract MT is ERC721Creator {
    constructor() ERC721Creator("ModelTesting", "MT") {}
}