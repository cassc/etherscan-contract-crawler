// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DarkMarkArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    DarkMarkArt Lost in Lust    //
//                                //
//                                //
////////////////////////////////////


contract DMArt is ERC721Creator {
    constructor() ERC721Creator("DarkMarkArt", "DMArt") {}
}