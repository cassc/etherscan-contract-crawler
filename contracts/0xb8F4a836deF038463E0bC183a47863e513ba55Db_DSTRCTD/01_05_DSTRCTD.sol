// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: distracted.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    d i s t r a c t e d.    //
//                            //
//                            //
////////////////////////////////


contract DSTRCTD is ERC1155Creator {
    constructor() ERC1155Creator("distracted.", "DSTRCTD") {}
}