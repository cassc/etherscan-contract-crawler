// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seattle's Mind
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Deep dive into Seattles Mind...    //
//                                       //
//                                       //
///////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Seattle's Mind", "SM") {}
}