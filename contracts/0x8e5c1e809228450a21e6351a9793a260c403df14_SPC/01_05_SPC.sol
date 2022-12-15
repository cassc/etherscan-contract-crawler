// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SoulplayClay NFTs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    SoulplayClay    //
//    DiscoverJoy     //
//                    //
//                    //
////////////////////////


contract SPC is ERC721Creator {
    constructor() ERC721Creator("SoulplayClay NFTs", "SPC") {}
}