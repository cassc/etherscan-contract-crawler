// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEMI'S FILM PHOTOGRAPHY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    FILM WILL NEVER DIE.    //
//                            //
//                            //
////////////////////////////////


contract DEMI is ERC721Creator {
    constructor() ERC721Creator("DEMI'S FILM PHOTOGRAPHY", "DEMI") {}
}