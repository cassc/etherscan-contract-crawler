// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Culture Guy Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Culture Guy Editions    //
//                            //
//                            //
////////////////////////////////


contract CLTGE is ERC1155Creator {
    constructor() ERC1155Creator("Culture Guy Editions", "CLTGE") {}
}