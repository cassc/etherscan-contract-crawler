// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Layer Beta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    © Layer, Inc    //
//                    //
//                    //
////////////////////////


contract LAYER is ERC721Creator {
    constructor() ERC721Creator("Layer Beta", "LAYER") {}
}