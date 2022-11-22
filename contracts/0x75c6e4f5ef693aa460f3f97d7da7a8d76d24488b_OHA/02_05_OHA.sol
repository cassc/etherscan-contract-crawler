// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OhHungryArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    OhHungryArtist🖤🤟🖤    //
//                            //
//                            //
////////////////////////////////


contract OHA is ERC721Creator {
    constructor() ERC721Creator("OhHungryArt", "OHA") {}
}