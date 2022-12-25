// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ilyar jabbari
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Artist ,Calligrapher,Painter ,Digital Art Creator    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract nftdigitalist is ERC721Creator {
    constructor() ERC721Creator("ilyar jabbari", "nftdigitalist") {}
}