// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Women in Love
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    Collection of expressive women portraits by OhHungryArtist    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract Love is ERC721Creator {
    constructor() ERC721Creator("Women in Love", "Love") {}
}