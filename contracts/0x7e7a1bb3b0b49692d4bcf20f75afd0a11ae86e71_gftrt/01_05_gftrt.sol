// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GiftART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//     ___________                                                   //
//     |  NUDE ART|                                                  //
//     |  WOMAN   |                                                  //
//     |  GIFTED  |                                                  //
//     |  1/1 ED. |                                                  //
//     |  NFT COL.|                                                  //
//      ~~~~~~~~~~~                                                  //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract gftrt is ERC721Creator {
    constructor() ERC721Creator("GiftART", "gftrt") {}
}