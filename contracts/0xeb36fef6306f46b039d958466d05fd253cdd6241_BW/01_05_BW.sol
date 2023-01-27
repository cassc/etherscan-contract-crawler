// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAND Wolf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Band Wolf               //
//    Punk, Rock, mixture     //
//                            //
//                            //
////////////////////////////////


contract BW is ERC721Creator {
    constructor() ERC721Creator("BAND Wolf", "BW") {}
}