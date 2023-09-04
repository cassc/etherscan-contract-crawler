// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: goose blocks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    goose blocks    //
//                    //
//                    //
////////////////////////


contract gbs is ERC721Creator {
    constructor() ERC721Creator("goose blocks", "gbs") {}
}