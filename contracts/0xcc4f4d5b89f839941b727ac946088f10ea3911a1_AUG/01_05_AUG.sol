// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DarkMarkArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Photographer lost in Lust    //
//                                 //
//                                 //
/////////////////////////////////////


contract AUG is ERC721Creator {
    constructor() ERC721Creator("DarkMarkArt", "AUG") {}
}