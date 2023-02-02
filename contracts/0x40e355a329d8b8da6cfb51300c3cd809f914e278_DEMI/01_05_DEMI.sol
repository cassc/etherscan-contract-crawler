// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEMI'S FILM PHOTOGRAPHY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    FILM WILL NEVER DIE.    //
//                            //
//                            //
////////////////////////////////


contract DEMI is ERC1155Creator {
    constructor() ERC1155Creator("DEMI'S FILM PHOTOGRAPHY", "DEMI") {}
}