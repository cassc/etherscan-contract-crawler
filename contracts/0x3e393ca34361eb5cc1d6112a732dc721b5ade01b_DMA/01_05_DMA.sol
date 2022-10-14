// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DarkMarkArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    DarkMarkArt lost in lust    //
//                                //
//                                //
////////////////////////////////////


contract DMA is ERC721Creator {
    constructor() ERC721Creator("DarkMarkArt", "DMA") {}
}