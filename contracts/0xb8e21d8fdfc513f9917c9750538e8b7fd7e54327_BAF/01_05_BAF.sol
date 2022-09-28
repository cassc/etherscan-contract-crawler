// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genesis Collector Special Edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    BryanFreudemanArt.eth    //
//                             //
//                             //
/////////////////////////////////


contract BAF is ERC721Creator {
    constructor() ERC721Creator("Genesis Collector Special Edition", "BAF") {}
}