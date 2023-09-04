// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Impression monster
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    I'm sick of impressions.    //
//                                //
//                                //
////////////////////////////////////


contract IMPM is ERC721Creator {
    constructor() ERC721Creator("Impression monster", "IMPM") {}
}