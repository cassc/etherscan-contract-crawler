// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Simian Samurai’s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Simian Samurai's NFT    //
//                            //
//                            //
////////////////////////////////


contract ONI is ERC721Creator {
    constructor() ERC721Creator(unicode"Simian Samurai’s", "ONI") {}
}